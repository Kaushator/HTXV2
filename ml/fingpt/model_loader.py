import os
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
from peft import PeftModel
import structlog
from typing import Optional, Dict, Any
import asyncio
from concurrent.futures import ThreadPoolExecutor

from .model_config import FinGPTConfig

logger = structlog.get_logger(__name__)

class FinGPTLoader:
    """Load and manage FinGPT model for local inference"""
    
    def __init__(self, config_path: str = "/app/fingpt/config.json"):
        self.config = FinGPTConfig(config_path)
        self.model = None
        self.tokenizer = None
        self.loaded = False
        self.executor = ThreadPoolExecutor(max_workers=1)
        
    async def load_model(self) -> bool:
        """Load model asynchronously"""
        try:
            logger.info("Loading FinGPT model...")
            
            # Check if local model exists
            if os.path.exists(self.config.model_path):
                await self._load_local_model()
            else:
                await self._download_and_load_model()
                
            self.loaded = True
            logger.info("FinGPT model loaded successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to load FinGPT model: {e}")
            return False
    
    async def _load_local_model(self):
        """Load model from local storage"""
        logger.info(f"Loading local model from {self.config.model_path}")
        
        def _load():
            # Load tokenizer
            self.tokenizer = AutoTokenizer.from_pretrained(
                self.config.model_path,
                trust_remote_code=True
            )
            
            # Load base model with quantization
            self.model = AutoModelForCausalLM.from_pretrained(
                self.config.model_path,
                quantization_config=self.config.quantization_config,
                device_map=self.config.rtx_4060_optimizations.get("device_map", "auto"),
                max_memory=self.config.rtx_4060_optimizations.get("max_memory"),
                low_cpu_mem_usage=self.config.rtx_4060_optimizations.get("low_cpu_mem_usage", True),
                trust_remote_code=True,
                torch_dtype=torch.float16,
            )
            
            # Load LoRA adapters if they exist
            lora_path = os.path.join(self.config.model_path, "lora_adapters")
            if os.path.exists(lora_path):
                logger.info("Loading LoRA adapters...")
                self.model = PeftModel.from_pretrained(self.model, lora_path)
            
            # Set pad token if not set
            if self.tokenizer.pad_token is None:
                self.tokenizer.pad_token = self.tokenizer.eos_token
                
        await asyncio.get_event_loop().run_in_executor(self.executor, _load)
    
    async def _download_and_load_model(self):
        """Download and load model from HuggingFace"""
        logger.info("Downloading FinGPT model from HuggingFace...")
        
        # TODO: Specify the actual FinGPT model requirements here. The model name should be set via environment variable FINGPT_MODEL_NAME or configuration.
        model_name = os.environ.get("FINGPT_MODEL_NAME", getattr(self.config, "model_name", "microsoft/DialoGPT-medium"))
        
        def _download_and_load():
            # Create model directory
            os.makedirs(self.config.model_path, exist_ok=True)
            
            # Load tokenizer
            self.tokenizer = AutoTokenizer.from_pretrained(
                model_name,
                trust_remote_code=True
            )
            
            # Load model with quantization
            self.model = AutoModelForCausalLM.from_pretrained(
                model_name,
                quantization_config=self.config.quantization_config,
                device_map=self.config.rtx_4060_optimizations.get("device_map", "auto"),
                max_memory=self.config.rtx_4060_optimizations.get("max_memory"),
                low_cpu_mem_usage=self.config.rtx_4060_optimizations.get("low_cpu_mem_usage", True),
                trust_remote_code=True,
                torch_dtype=torch.float16,
            )
            
            # Save model locally
            self.model.save_pretrained(self.config.model_path)
            self.tokenizer.save_pretrained(self.config.model_path)
            
            # Set pad token if not set
            if self.tokenizer.pad_token is None:
                self.tokenizer.pad_token = self.tokenizer.eos_token
                
        await asyncio.get_event_loop().run_in_executor(self.executor, _download_and_load)
    
    async def generate_text(self, prompt: str, **kwargs) -> str:
        """Generate text using the loaded model"""
        if not self.loaded:
            raise RuntimeError("Model not loaded. Call load_model() first.")
        
        def _generate():
            # Tokenize input
            inputs = self.tokenizer.encode(prompt, return_tensors="pt")
            if torch.cuda.is_available():
                inputs = inputs.to("cuda")
            
            # Generate with model
            generation_config = {**self.config.generation_config, **kwargs}
            
            with torch.no_grad():
                outputs = self.model.generate(
                    inputs,
                    **generation_config
                )
            
            # Decode output
            generated_text = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
            
            # Remove input prompt from output
            if generated_text.startswith(prompt):
                generated_text = generated_text[len(prompt):].strip()
            
            return generated_text
        
        return await asyncio.get_event_loop().run_in_executor(self.executor, _generate)
    
    def get_model_info(self) -> Dict[str, Any]:
        """Get model information"""
        if not self.loaded:
            return {"status": "not_loaded"}
        
        return {
            "status": "loaded",
            "model_name": self.config.model_name,
            "device": str(self.model.device) if self.model else "unknown",
            "memory_usage": torch.cuda.memory_allocated() if torch.cuda.is_available() else 0,
            "config": self.config.config
        }