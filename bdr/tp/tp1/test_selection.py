import types
import unittest

from tp1 import *
from disque import *


class test_selection(unittest.TestCase):

    def test_selection_flux(self):
        tbl = table({"a": (1, 10), "b": (1, 10), "c": (1, 10)}, nb=10)
        sel = selection(tbl,lambda tp : tp['a']%2==0)
        self.assertTrue(isinstance(sel, types.GeneratorType),
                         "La sélection doit produire un flux.")

    def test_selection(self):
        tbl = [{"a": 1, "b": 2, "c": 3},
               {"a": 1, "b": 3, "c": 4},
               {"a": 5, "b": 2, "c": 3},
               {"a": 1, "b": 8, "c": 4},
               {"a": 5, "b": 2, "c": 3}]
        self.assertEqual(list(selection(tbl, lambda tp: (tp['a'] + tp['b'] +
                                                         tp['c']) % 2 == 0)),
                         [tp for tp in tbl if (tp['a'] + tp['b'] +
                                               tp['c']) % 2 == 0],
                         "La sémantique de la sélection n'est pas respectée.")

if __name__ == '__main__':
    unittest.main()
