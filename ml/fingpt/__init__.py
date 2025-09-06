"""
FinGPT Local Inference Service for RTX 4060
"""

from .model_config import FinGPTConfig
from .model_loader import FinGPTLoader

__all__ = ["FinGPTConfig", "FinGPTLoader"]