"""A complete, self-contained Manim presentation of one small MLP."""
from manim import *
import numpy as np
from config import CFG
from training import simulate


class MLPTraining(Scene):
    def construct(self):
        c = CFG
        self.camera.background_color = c.background
        self.states = simulate(c)
        self.speed = c.speed
        if not np.isfinite(c.speed) or c.speed <= 0:
            raise ValueError('speed must be positive and finite')
        self.make_network()
        title = Text('Wie ein neuronales Netz lernt', font_size=31, color=c.text).to_edge(UP, buff=0.2)
        stage = Text('1  Netzwerk aufbauen', font_size=22, color=c.activation_color).move_to([0,3.05,0])
        self.play(FadeIn(title), FadeIn(stage), run_time=1.5/self.speed)
        for i in range(5):
            if i:
                self.play(FadeIn(self.edges[i-1]), run_time=0.65/self.speed)
            self.play(FadeIn(self.nodes[i]), FadeIn(self.layer_labels[i]), run_time=0.75/self.speed)
        self.play(FadeIn(self.input_labels), run_time=1.3/self.speed)
        note = Text('Beispielwerte · dimensionslos', font_size=18, color=c.muted).move_to([-4.6,-1.38,0])
        legend = VGroup(Text('Gewicht +',font_size=17,color=c.positive), Text('Gewicht −',font_size=17,color=c.negative), Text('Aktivierung',font_size=17,color=c.activation_color), Text('Gradient',font_size=17,color=c.backward)).arrange(RIGHT,buff=0.45).move_to([0,-3.55,0])
        self.play(FadeIn(note), FadeIn(legend), run_time=1/self.speed)
        self.wait(2/self.speed)

        self.change_stage(stage, '2  Forward Pass')
        first = self.states[0]
        self.play(*self.activate(0, first.activations[0]), run_time=1.5/self.speed)
        self.wait(1/self.speed)
        for layer in range(4):
            self.flow(layer, forward=True, duration=2.1)
            self.play(*self.activate(layer+1, first.activations[layer+1]), run_time=1.2/self.speed)
            if layer == 0:
                name = {'tanh': r'\tanh', 'sigmoid': r'\mathrm{sigmoid}', 'relu': r'\mathrm{ReLU}'}[c.activation]
                formula = MathTex(r'z_j=\sum_i w_{ji}a_i+b_j', r'\qquad', r'a_j='+name+r'(z_j)', font_size=29, color=c.text).move_to([0,-1.75,0])
                example = MathTex(r'z_1='+f'{first.zs[0][0]:.3f}'+r',\qquad a_1='+f'{first.activations[1][0]:.3f}', font_size=26, color=c.activation_color).move_to([0,-2.4,0])
                self.play(Write(formula), FadeIn(example), run_time=2/self.speed)
                self.wait(3/self.speed)
                self.play(FadeOut(formula), FadeOut(example), run_time=0.7/self.speed)

        self.change_stage(stage, '3  Vorhersage und Fehler')
        loss_text = self.loss_panel(first)
        self.play(FadeIn(loss_text), run_time=1.5/self.speed)
        self.wait(5/self.speed)
        self.play(FadeOut(loss_text), run_time=0.6/self.speed)

        self.change_stage(stage, '4  Backpropagation und Update')
        update = MathTex(r'w\leftarrow w-\eta\frac{\partial\mathcal L}{\partial w}', font_size=34, color=c.text).move_to([0,-1.8,0])
        update_note = Text('Großer Gradient  →  stärkeres Rückwärtssignal', font_size=20, color=c.backward).move_to([0,-2.4,0])
        self.play(Write(update), FadeIn(update_note), run_time=1.5/self.speed)
        for layer in reversed(range(4)):
            self.flow(layer, forward=False, duration=2.0, gradients=first.grad_weights[layer])
        self.show_weights(self.states[1], duration=2)
        self.wait(2/self.speed)
        self.play(FadeOut(update), FadeOut(update_note), FadeOut(note), FadeOut(legend), run_time=0.7/self.speed)

        self.change_stage(stage, '5  Training über mehrere Epochen')
        # Replay the measured trajectory from the initial state.
        self.show_weights(self.states[0], duration=0.5)
        self.setup_plot()
        self.play(Create(self.axes), FadeIn(self.plot_labels), run_time=1.2/self.speed)
        self.draw_initial_point()
        for epoch in range(1, len(self.states)):
            previous, state = self.states[epoch-1], self.states[epoch]
            for layer in range(4): self.flow(layer, True, 0.12)
            for layer in reversed(range(4)): self.flow(layer, False, 0.12, previous.grad_weights[layer])
            self.show_weights(state, duration=0.18)
            self.plot_epoch(epoch, state)
        self.wait(4/self.speed)

    def change_stage(self, old, label):
        new = Text(label, font_size=22, color=CFG.activation_color).move_to(old)
        self.play(Transform(old, new), run_time=0.6/self.speed)

    def make_network(self):
        c = CFG
        sizes = (6, *c.hidden_sizes, 1)
        xs = [-4.6, -2.3, 0, 2.3, 4.6]
        self.nodes, self.edges, self.layer_labels = [], [], []
        names = ['Input\nLayer', 'Hidden\nLayer 1', 'Hidden\nLayer 2', 'Hidden\nLayer 3', 'Output\nLayer']
        for x, n, name in zip(xs, sizes, names):
            ys = np.linspace(2.0, -0.55, n) if n > 1 else [0.72]
            radius = min(0.15, 1.0/max(n, 1))
            group = VGroup(*[Circle(radius=radius, stroke_color=c.text, stroke_width=2, fill_color=c.background, fill_opacity=1).move_to([x,y,0]) for y in ys])
            self.nodes.append(group)
            self.layer_labels.append(Text(name, font_size=17, line_spacing=0.7, color=c.text).move_to([x,2.48,0]))
        self.edge_arrays = []
        for l, weights in enumerate(self.states[0].weights):
            arr = []
            for j in range(weights.shape[0]):
                row = []
                for i in range(weights.shape[1]):
                    line = Line(self.nodes[l][i].get_center(), self.nodes[l+1][j].get_center())
                    self.set_weight_style(line, weights[j,i])
                    row.append(line)
                arr.append(row)
            self.edge_arrays.append(arr)
            self.edges.append(VGroup(*[line for row in arr for line in row]))
        labels = []
        for i, (name, value) in enumerate(zip(c.input_names, c.input_values)):
            label = MathTex(name, '=', f'{value:.2f}', font_size=25, color=c.text)
            label.next_to(self.nodes[0][i], LEFT, buff=0.18)
            labels.append(label)
        self.input_labels = VGroup(*labels)

    def set_weight_style(self, line, weight):
        mag = min(abs(float(weight)), 1.0)
        line.set_stroke(CFG.positive if weight >= 0 else CFG.negative, width=0.7+2.4*mag, opacity=0.14+0.56*mag)
        return line

    def activate(self, layer, values):
        return [node.animate.set_fill(CFG.activation_color if value >= 0 else CFG.negative,
                    opacity=0.18+0.72*min(abs(float(value)),1)) for node,value in zip(self.nodes[layer], values)]

    def flow(self, layer, forward, duration, gradients=None):
        arr = self.edge_arrays[layer]
        active = layer + 1 if forward else layer
        for index, group in enumerate(self.nodes):
            for node in group: node.set_stroke(CFG.text if index == active else CFG.muted, width=2.5 if index == active else 1.2)
        rows, cols = len(arr), len(arr[0])
        pairs = [(0,0), (rows//2,cols//2), (rows-1,cols-1)]
        if gradients is not None:
            flat = np.argsort(np.abs(gradients).ravel())[-min(4, gradients.size):]
            pairs = [np.unravel_index(int(k), gradients.shape) for k in flat]
        peak = max(float(np.max(np.abs(gradients))), 1e-12) if gradients is not None else 1
        dots, animations = VGroup(), []
        for j,i in pairs:
            edge = arr[j][i]
            strength = abs(float(gradients[j,i]))/peak if gradients is not None else 0.7
            dot = Dot(radius=0.035+0.045*strength, color=CFG.backward if not forward else CFG.activation_color)
            path = Line(edge.get_start(), edge.get_end()) if forward else Line(edge.get_end(), edge.get_start())
            dot.move_to(path.get_start()); dots.add(dot)
            animations.append(MoveAlongPath(dot, path, rate_func=linear))
        self.add(dots)
        self.play(*animations, run_time=duration/self.speed)
        self.remove(dots)

    def show_weights(self, state, duration):
        animations = []
        for l, matrix in enumerate(state.weights):
            for j,row in enumerate(self.edge_arrays[l]):
                for i,line in enumerate(row):
                    target = line.copy(); self.set_weight_style(target, matrix[j,i])
                    animations.append(Transform(line,target))
        for l, acts in enumerate(state.activations): animations.extend(self.activate(l,acts))
        self.play(*animations, run_time=duration/self.speed)

    def loss_panel(self, state):
        a = MathTex(r'\hat y='+f'{state.prediction:.3f}', r'\qquad y='+f'{CFG.target:.3f}', font_size=36, color=CFG.text)
        b = MathTex(r'\mathcal L=(\hat y-y)^2='+f'{state.loss:.4f}', font_size=32, color=CFG.activation_color)
        return VGroup(a,b).arrange(DOWN,buff=0.3).move_to([0,-2.1,0])

    def setup_plot(self):
        ymax = max(self.states[0].loss * 1.12, 0.001)
        self.axes = Axes(x_range=[0,CFG.epochs, max(1,CFG.epochs//4)], y_range=[0,ymax,ymax/2],
                         x_length=5.8, y_length=1.05, axis_config={'color':CFG.muted,'stroke_width':2,'include_ticks':False}, tips=False).move_to([2.7,-2.65,0])
        self.plot_labels = VGroup(Text('Loss',font_size=20,color=CFG.text).next_to(self.axes,LEFT,buff=0.15),
                                  Text('Epochen',font_size=18,color=CFG.muted).next_to(self.axes,DOWN,buff=0.08),
                                  Text(f'{ymax:.2f}',font_size=16,color=CFG.muted).next_to(self.axes.c2p(0,ymax),LEFT,buff=0.08))
        self.counter = Text('Epoche 0',font_size=24,color=CFG.text).move_to([-3.6,-2.15,0])
        self.readout = Text(f'Loss {self.states[0].loss:.4f}',font_size=23,color=CFG.activation_color).move_to([-3.6,-2.65,0])
        self.pred = Text(f'Vorhersage {self.states[0].prediction:.3f}',font_size=20,color=CFG.text).move_to([-3.6,-3.15,0])
        self.add(self.counter,self.readout,self.pred)

    def draw_initial_point(self):
        self.add(Dot(self.axes.c2p(0,self.states[0].loss),radius=0.045,color=CFG.activation_color))

    def plot_epoch(self, epoch, state):
        previous = self.states[epoch-1]
        segment = Line(self.axes.c2p(epoch-1,previous.loss),self.axes.c2p(epoch,state.loss),color=CFG.activation_color,stroke_width=3)
        counter = Text(f'Epoche {epoch}',font_size=24,color=CFG.text).move_to(self.counter)
        readout = Text(f'Loss {state.loss:.4f}',font_size=23,color=CFG.activation_color).move_to(self.readout)
        pred = Text(f'Vorhersage {state.prediction:.3f}',font_size=20,color=CFG.text).move_to(self.pred)
        self.play(Create(segment), Transform(self.counter,counter), Transform(self.readout,readout), Transform(self.pred,pred),run_time=0.35/self.speed)
