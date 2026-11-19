import unittest
from dataclasses import replace
import numpy as np
from config import CFG
from training import simulate, evaluate

class TrainingTests(unittest.TestCase):
    def test_gradients_against_finite_differences(self):
        for activation in ('tanh', 'sigmoid', 'relu'):
            cfg = replace(CFG, activation=activation, hidden_sizes=(3,4,2))
            state = simulate(cfg)[0]
            eps = 1e-6
            for l, matrix in enumerate(state.weights):
                for index in [(0,0), (matrix.shape[0]-1,matrix.shape[1]-1)]:
                    weights = [w.copy() for w in state.weights]
                    weights[l][index] += eps
                    plus = evaluate(weights,state.biases,cfg.input_values,cfg.target,activation).loss
                    weights[l][index] -= 2*eps
                    minus = evaluate(weights,state.biases,cfg.input_values,cfg.target,activation).loss
                    self.assertAlmostEqual((plus-minus)/(2*eps),state.grad_weights[l][index],places=5)
                biases = [b.copy() for b in state.biases]
                biases[l][0] += eps
                plus = evaluate(state.weights,biases,cfg.input_values,cfg.target,activation).loss
                biases[l][0] -= 2*eps
                minus = evaluate(state.weights,biases,cfg.input_values,cfg.target,activation).loss
                self.assertAlmostEqual((plus-minus)/(2*eps),state.grad_biases[l][0],places=5)

    def test_training_is_finite_decreasing_and_reproducible(self):
        for activation in ('tanh','sigmoid','relu'):
            cfg = replace(CFG,activation=activation,hidden_sizes=(3,4,2))
            a, b = simulate(cfg), simulate(cfg)
            losses = np.array([s.loss for s in a])
            self.assertTrue(np.isfinite(losses).all())
            self.assertTrue(np.all(np.diff(losses) <= 1e-14))
            self.assertLess(losses[-1], losses[0])
            np.testing.assert_array_equal(losses, [s.loss for s in b])
            for state in a:
                for value in state.weights + state.biases + state.activations + state.grad_weights + state.grad_biases:
                    self.assertTrue(np.isfinite(value).all())

    def test_invalid_shape(self):
        with self.assertRaises(ValueError): simulate(replace(CFG,hidden_sizes=(2,3)))

if __name__ == '__main__': unittest.main()
