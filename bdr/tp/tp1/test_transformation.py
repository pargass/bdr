import unittest
import types
from tp1 import *
from disque import *


class test_transformation(unittest.TestCase):
    def test_transformation_flux(self):
        table = [{"a": 1, "b": 2, "c": 3},
                 {"a": 1, "b": 3, "c": 4},
                 {"a": 5, "b": 2, "c": 3},
                 {"a": 1, "b": 8, "c": 4},
                 {"a": 5, "b": 2, "c": 3}
                 ]
        flux = transformation(table,
                              lambda tp: {'d': tp['a'] + tp['b'] * 2 +
                                          tp['c'] * 3})
        self.assertTrue(isinstance(flux, types.GeneratorType),
                         "La transformation doit produire un flux.")

    def test_transformation(self):
        table = [{"a": 1, "b": 2, "c": 3},
                 {"a": 1, "b": 3, "c": 4},
                 {"a": 5, "b": 2, "c": 3},
                 {"a": 1, "b": 8, "c": 4},
                 {"a": 5, "b": 2, "c": 3}
                 ]
        flux = transformation(table,
                          lambda tp: {'d': tp['a'] + tp['b'] * 2 +
                                      tp['c'] * 3})
        self.assertEqual(list(flux),
                         [{"d": 14},
                          {"d": 19},
                          {"d": 18},
                          {"d": 29},
                          {"d": 18}],
                         "La sémantique de la projection n'est pas respectée.")


if __name__ == '__main__':
    unittest.main()
