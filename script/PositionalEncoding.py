import math

import torch
from torch import nn


class PositionalEncoding1d(nn.Module):
    def __init__(self, emb_dim, max_features=5000):
        super().__init__()
        pos = torch.arange(0, max_features, dtype=torch.float).unsqueeze(1)
        depth = torch.arange(0, emb_dim, step=2).float()
        # log10000 is a MAGIC number! See the original publication and related
        # blog post for more information.
        # https://arxiv.org/abs/1706.03762
        # https://kazemnejad.com/blog/transformer_architecture_positional_encoding
        freq = torch.exp(-depth * math.log(10000.0) / emb_dim)

        pe = torch.zeros(max_features, emb_dim)
        pe[:, 0::2] = torch.sin(pos * freq)
        pe[:, 1::2] = torch.cos(pos * freq)
        pe = pe.unsqueeze(0)
        self.register_buffer('pe', pe)

    def forward(self, x):
        x = self.pe[:, :x.size(1), :]
        print("The output shape of position encoding is ", x.shape)
        return x
