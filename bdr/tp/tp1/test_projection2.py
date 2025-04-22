import unittest
import types
from tp1 import *
from disque import *


class test_projection2(unittest.TestCase):
    def test_projection2_flux(self):
        tbl = table({"a": (1, 10), "b": (1, 10), "c": (1, 10)}, nb=10)
        champs = ["a", "c"]
        self.assertTrue(isinstance(projection2(tbl, champs),
                                   types.GeneratorType),
                         "La projection2 doit produire un flux.")

    def test_projection2(self):
        table = [{"a": 1, "b": 2, "c": 3},
                 {"a": 1, "b": 3, "c": 4},
                 {"a": 5, "b": 2, "c": 3},
                 {"a": 1, "b": 8, "c": 4},
                 {"a": 5, "b": 2, "c": 3}
                 ]
        champs = ["a", "c"]
        self.assertEqual(list(projection2(table, champs)),
                         [{"a": 1, "c": 3},
                          {"a": 1, "c": 4},
                          {"a": 5, "c": 3},
                          {"a": 1, "c": 4},
                          {"a": 5, "c": 3}],
                         "La sémantique de la projection2 n'est pas respectée.")


    def test_projection2_absent_field(self):
        table = [{"a": 1, "b": 2, "c": 3},
                 {"a": 1, "b": 3, "c": 4},
                 {"a": 5, "b": 2, "c": 3},
                 {"a": 1, "b": 8, "c": 4},
                 {"a": 5, "b": 2, "c": 3}
                 ]
        champs = ["a", "c", "d"]
        self.assertRaises(KeyError, lambda _ : list(projection2(table, champs)),
                          "Lorsque la projection2 est réalisée sur un attribut \
                          qui n'est pas présent dans les tuples de la table \
                          passée en argument, l'exception KeyError doit être \
                          levée.")



if __name__ == '__main__':
    unittest.main()
