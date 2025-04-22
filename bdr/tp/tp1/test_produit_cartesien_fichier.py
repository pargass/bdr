import types
import unittest

from tp1 import *
from disque import *


class test_produit_cartesien_fichier(unittest.TestCase):

    def test_produit_cartesien_fichier_flux(self):
        schema1 = {'a' : (0,10), 'b' : (1,10000000)}
        schema2 = {'c' : (0,10), 'd' : (1,10000000)}
        tbl1 = table(schema1, nb=10)
        tbl2 = table(schema2, nb=10)
        fichier1 = "/tmp/tbl1.table"
        fichier2 = "/tmp/tbl2.table"
        mem_sur_disque(tbl1, fichier1)
        mem_sur_disque(tbl2, fichier2)
        pc = produit_cartesien_fichier(fichier1, fichier2)
        self.assertTrue(isinstance(pc, types.GeneratorType),
                         "Le produit cartésien doit produire un flux.")

    def test_produit_cartesien_fichier_vide_1(self):
        tbl1 = []
        tbl2 = [{"a": 1, "b": 2, "c": 1},
                {"a": 1, "b": 3, "c": 4},
                {"a": 5, "b": 2, "c": 2},
                {"a": 1, "b": 8, "c": 4},
                {"a": 5, "b": 1, "c": 3}]
        fichier1 = "/tmp/tbl1.table"
        fichier2 = "/tmp/tbl2.table"
        mem_sur_disque(tbl1, fichier1)
        mem_sur_disque(tbl2, fichier2)
        pc = produit_cartesien_fichier(fichier1, fichier2)
        self.assertEqual(list(pc),
                         [],
                         "Lorsque la première table est vide le produit cartésien l'est aussi.")


    def test_produit_cartesien_fichier_vide_2(self):
        tbl1 = [{"a": 1, "b": 2, "c": 1},
                {"a": 1, "b": 3, "c": 4},
                {"a": 5, "b": 2, "c": 2},
                {"a": 1, "b": 8, "c": 4},
                {"a": 5, "b": 1, "c": 3}]
        tbl2 = []
        fichier1 = "/tmp/tbl1.table"
        fichier2 = "/tmp/tbl2.table"
        mem_sur_disque(tbl1, fichier1)
        mem_sur_disque(tbl2, fichier2)
        pc = produit_cartesien_fichier(fichier1, fichier2)
        self.assertEqual(list(pc),
                         [],
                         "Lorsque la seconde table est vide le produit cartésien l'est aussi.")

    def test_produit_cartesien_fichier_vide_2(self):
        tbl1 = [{"a": 1, "b": 2, "c": 1},
                {"a": 1, "b": 3, "c": 4},
                {"a": 5, "b": 2, "c": 2},
                {"a": 1, "b": 8, "c": 4},
                {"a": 5, "b": 1, "c": 3}]
        tbl2 = [{"e": 4, "f": 4},
                {"e": 5, "f": 5}]
        fichier1 = "/tmp/tbl1.table"
        fichier2 = "/tmp/tbl2.table"
        mem_sur_disque(tbl1, fichier1)
        mem_sur_disque(tbl2, fichier2)
        pc = produit_cartesien_fichier(fichier1, fichier2)
        self.assertEqual(list(pc),
                         [appariement(t1, t2) for t1 in tbl1 for t2 in tbl2],
                         "La sémantique du produit cartésien n'est pas respectée.")


if __name__ == '__main__':
    unittest.main()
