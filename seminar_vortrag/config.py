"""All choices affecting the training and presentation live here."""
from dataclasses import dataclass

@dataclass(frozen=True)
class Settings:
    input_names: tuple = (r'L', r'B', r'H', r'E', r'\nu', r'F')
    input_values: tuple = (0.8, 0.4, 0.6, 0.9, 0.3, 0.7)
    hidden_sizes: tuple = (8, 6, 4)
    target: float = 0.8
    activation: str = 'tanh'
    learning_rate: float = 0.05
    epochs: int = 24
    seed: int = 42
    speed: float = 1.0
    preview_resolution: tuple = (854, 480)
    final_resolution: tuple = (1920, 1080)
    preview_fps: int = 15
    final_fps: int = 30
    background: str = '#101722'
    positive: str = '#4FAFE8'
    negative: str = '#EF7286'
    activation_color: str = '#F5D76E'
    backward: str = '#FF9F55'
    muted: str = '#8797A8'
    text: str = '#EAF2FA'

CFG = Settings()
