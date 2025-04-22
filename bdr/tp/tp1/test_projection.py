import unittest
import types
from tp1 import *
from disque import *


class test_projection(unittest.TestCase):

    def test_projection_flux(self):
        tbl = table({"a": (1, 10), "b": (1, 10), "c": (1, 10)}, nb=10)
        champs = ["a", "c"]
        self.assertTrue(isinstance(projection(tbl, champs), types.GeneratorType),
                         "La projection doit produire un flux.")

    def test_projection(self):
        table = [{"a": 1, "b": 2, "c": 3},
                 {"a": 1, "b": 3, "c": 4},
                 {"a": 5, "b": 2, "c": 3},
                 {"a": 1, "b": 8, "c": 4},
                 {"a": 5, "b": 2, "c": 3}
                 ]
        champs = ["a", "c"]
        self.assertEqual(list(projection(table, champs)),
                         [{"a": 1, "c": 3},
                          {"a": 1, "c": 4},
                          {"a": 5, "c": 3},
                          {"a": 1, "c": 4},
                          {"a": 5, "c": 3}],
                         "La sémantique de la projection n'est pas respectée.")

    def test_projection_absent_field(self):
        table = [{"a": 1, "b": 2, "c": 3},
                 {"a": 1, "b": 3, "c": 4},
                 {"a": 5, "b": 2, "c": 3},
                 {"a": 1, "b": 8, "c": 4},
                 {"a": 5, "b": 2, "c": 3}
                 ]
        champs = ["a", "c", "d"]
        self.assertRaises(KeyError, lambda _ : list(projection(table, champs)),
                          "Lorsque la projection est réalisée sur un attribut \
                          qui n'est pas présent dans les tuples de la table \
                          passée en argument, l'exception KeyError doit être \
                          levée.")



if __name__ == '__main__':
    unittest.main()
