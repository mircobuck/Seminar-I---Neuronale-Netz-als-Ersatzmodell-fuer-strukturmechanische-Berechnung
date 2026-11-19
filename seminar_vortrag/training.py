"""Small deterministic MLP, deliberately independent of Manim."""
from dataclasses import dataclass
import numpy as np
from config import CFG

@dataclass
class State:
    weights: list
    biases: list
    activations: list
    zs: list
    prediction: float
    loss: float
    grad_weights: list
    grad_biases: list
    learning_rate: float = 0.0

def activation(z, name):
    if name == 'tanh': return np.tanh(z)
    if name == 'sigmoid': return 1 / (1 + np.exp(-np.clip(z, -500, 500)))
    if name == 'relu': return np.maximum(z, 0)
    raise ValueError('activation must be tanh, sigmoid or relu')

def derivative(z, name):
    a = activation(z, name)
    if name == 'tanh': return 1 - a*a
    if name == 'sigmoid': return a*(1-a)
    return (z > 0).astype(float)

def evaluate(weights, biases, x, y, name):
    acts = [np.asarray(x, dtype=float)]
    zs = []
    for i, (w, b) in enumerate(zip(weights, biases)):
        z = w @ acts[-1] + b
        zs.append(z)
        acts.append(z if i == len(weights)-1 else activation(z, name))
    prediction = float(acts[-1][0])
    loss = float((prediction-y)**2)
    delta = np.array([2*(prediction-y)])
    gw, gb = [None]*len(weights), [None]*len(weights)
    for i in range(len(weights)-1, -1, -1):
        gw[i] = np.outer(delta, acts[i]); gb[i] = delta.copy()
        if i: delta = (weights[i].T @ delta) * derivative(zs[i-1], name)
    return State([w.copy() for w in weights], [b.copy() for b in biases], acts, zs,
                 prediction, loss, gw, gb)

def simulate(cfg=CFG):
    x = np.asarray(cfg.input_values, dtype=float)
    if len(cfg.input_names) != 6 or x.shape != (6,) or len(cfg.hidden_sizes) != 3:
        raise ValueError('Six inputs and exactly three hidden layers are required')
    if any(not isinstance(n, int) or n < 1 or n > 12 for n in cfg.hidden_sizes):
        raise ValueError('Hidden layer sizes must be integers from 1 to 12')
    if not np.isfinite(x).all() or not np.isfinite(cfg.target) or not np.isfinite(cfg.learning_rate) or cfg.learning_rate <= 0 or cfg.epochs < 1:
        raise ValueError('Invalid input, target, learning rate or epoch count')
    sizes = (6, *cfg.hidden_sizes, 1)
    rng = np.random.default_rng(cfg.seed)
    weights = [rng.uniform(-np.sqrt(6/(a+b)), np.sqrt(6/(a+b)), (b,a)) for a,b in zip(sizes, sizes[1:])]
    biases = [np.zeros(n) for n in sizes[1:]]
    states = [evaluate(weights, biases, x, cfg.target, cfg.activation)]
    for _ in range(cfg.epochs):
        old = states[-1]; rate = cfg.learning_rate
        for _ in range(60):
            w = [a-rate*g for a,g in zip(old.weights, old.grad_weights)]
            b = [a-rate*g for a,g in zip(old.biases, old.grad_biases)]
            new = evaluate(w, b, x, cfg.target, cfg.activation)
            if np.isfinite(new.loss) and new.loss <= old.loss: break
            rate *= 0.5
        else: raise RuntimeError('Could not find a finite, non-increasing update')
        new.learning_rate = rate
        states.append(new)
    return states
