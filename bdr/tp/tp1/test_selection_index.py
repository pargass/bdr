import types
import unittest

from tp1 import *
from disque import *


class test_selection_index(unittest.TestCase):

    def test_selection_index_flux(self):
        schema = {'a' : (0,10), 'b' : (1,10000000)}
        tbl = table(schema, nb=10)
        fichier = "/tmp/tbl.table"
        mem_sur_disque(tbl, fichier)
        idx = index_fichier(fichier, 'a')
        sel = selection_index(fichier, idx, [0, 1, 2])
        self.assertTrue(isinstance(sel, types.GeneratorType),
                         "La sélection avec index doit produire un flux.")

    def test_selection_index(self):
        tbl = [{"a": 1, "b": 2, "c": 1},
               {"a": 1, "b": 3, "c": 4},
               {"a": 5, "b": 2, "c": 2},
               {"a": 1, "b": 8, "c": 4},
               {"a": 5, "b": 1, "c": 3}]
        fichier = "/tmp/tbl.table"
        mem_sur_disque(tbl, fichier)
        idx = index_fichier(fichier, 'b')
        sel = selection_index(fichier, idx, [1, 2])
        self.assertEqual(sorted(list(sel), key=lambda tp: tp["c"]),
                         [{"a": 1, "b": 2, "c": 1},
                          {"a": 5, "b": 2, "c": 2},
                          {"a": 5, "b": 1, "c": 3}],
                         "La sémantique de la sélection n'est pas respectée.")

if __name__ == '__main__':
    unittest.main()
