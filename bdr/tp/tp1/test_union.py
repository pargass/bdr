import unittest
import types
from tp1 import *
from disque import *


class test_projection(unittest.TestCase):

    def test_union_flux(self):
        tbl1 = table({"a": (1, 10), "b": (1, 10), "c": (1, 10)}, nb=10)
        tbl2 = table({"a": (1, 10), "b": (1, 10), "c": (1, 10)}, nb=10)
        tbl = union(tbl1,tbl2)
        self.assertTrue(isinstance(tbl, types.GeneratorType),
                         "L'union doit produire un flux.")
        for i in range(10):
            next(tbl)
        self.assertTrue(isinstance(tbl, types.GeneratorType),
                         "L'union doit produire un flux.")


    def test_union(self):
        tbl1 = [{"a": 1, "b": 2, "c": 3},
                 {"a": 1, "b": 3, "c": 4},
                 {"a": 5, "b": 2, "c": 3}]
        tbl2 = [{"a": 1, "b": 8, "c": 4},
                {"a": 5, "b": 2, "c": 3}]
        self.assertEqual(list(union(tbl1, tbl2)),
                         tbl1+tbl2,
                         "La sémantique de l'union n'est pas respectée.")

if __name__ == '__main__':
    unittest.main()
