import os
import json
import torch
from transformers import (
    AutoTokenizer,
    AutoModelForCausalLM,
    BitsAndBytesConfig,
    TrainingArguments
)
from peft import (
    LoraConfig,
    get_peft_model,
    prepare_model_for_kbit_training,
    PeftModel
)
import structlog

logger = structlog.get_logger(__name__)

class FinGPTConfig:
    """Configuration for FinGPT local inference on RTX 4060"""
    
    def __init__(self, config_path: str = "/app/fingpt/config.json"):
        with open(config_path, 'r') as f:
            self.config = json.load(f)
        
        # GPU detection and setup
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        if self.device == "cuda":
            self.gpu_memory = torch.cuda.get_device_properties(0).total_memory
            logger.info(f"GPU detected: {torch.cuda.get_device_name(0)}")
            logger.info(f"GPU memory: {self.gpu_memory / 1024**3:.1f}GB")
        
    @property
    def model_name(self) -> str:
        return self.config.get("model_name", "microsoft/DialoGPT-medium")
    
    @property
    def model_path(self) -> str:
        return self.config.get("model_path", "/app/models/fingpt")
    
    @property
    def quantization_config(self) -> BitsAndBytesConfig:
        """4-bit quantization for RTX 4060"""
        return BitsAndBytesConfig(
            load_in_4bit=self.config.get("load_in_4bit", True),
            bnb_4bit_compute_dtype=getattr(torch, self.config.get("bnb_4bit_compute_dtype", "float16")),
            bnb_4bit_use_double_quant=self.config.get("bnb_4bit_use_double_quant", True),
            bnb_4bit_quant_type=self.config.get("bnb_4bit_quant_type", "nf4"),
        )
    
    @property
    def lora_config(self) -> LoraConfig:
        """LoRA configuration for memory efficiency"""
        lora_config = self.config.get("lora_config", {})
        return LoraConfig(
            r=lora_config.get("r", 16),
            lora_alpha=lora_config.get("lora_alpha", 32),
            target_modules=lora_config.get("target_modules", ["q_proj", "v_proj"]),
            lora_dropout=lora_config.get("lora_dropout", 0.05),
            bias=lora_config.get("bias", "none"),
            task_type=lora_config.get("task_type", "CAUSAL_LM"),
        )
    
    @property
    def generation_config(self) -> dict:
        """Generation parameters"""
        return {
            "max_length": self.config.get("max_length", 2048),
            "temperature": self.config.get("temperature", 0.7),
            "top_p": self.config.get("top_p", 0.9),
            "do_sample": self.config.get("do_sample", True),
            "pad_token_id": self.config.get("pad_token_id", 0),
            "eos_token_id": self.config.get("eos_token_id", 2),
            "use_cache": self.config.get("use_cache", True),
        }
    
    @property
    def rtx_4060_optimizations(self) -> dict:
        """RTX 4060 specific optimizations"""
        return self.config.get("rtx_4060_optimizations", {
            "max_memory": {"0": "7GB"},
            "low_cpu_mem_usage": True,
            "device_map": "auto",
        })