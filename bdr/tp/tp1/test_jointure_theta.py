import types
import unittest

from tp1 import *
from disque import *


class test_jointure_theta(unittest.TestCase):

    def test_jointure_theta_flux(self):
        schema1 = {'a' : (0,10), 'b' : (1,10000000)}
        schema2 = {'c' : (0,10), 'd' : (1,10000000)}
        tbl1 = table(schema1, nb=10)
        tbl2 = table(schema2, nb=10)
        fichier1 = "/tmp/tbl1.table"
        fichier2 = "/tmp/tbl2.table"
        mem_sur_disque(tbl1, fichier1)
        mem_sur_disque(tbl2, fichier2)
        jt = jointure_theta(fichier1,
                            fichier2,
                            lambda tp: tp['a'] % 2 == tp['c'] % 2)
        self.assertTrue(isinstance(jt, types.GeneratorType),
                        "Le jointure theta doit produire un flux.")

    def test_jointure_theta_fichier_vide_1(self):
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
        jt = jointure_theta(fichier1,
                            fichier2,
                            lambda tp: True)
        self.assertEqual(list(jt),
                         [],
                         "Lorsque la première table est vide la jointure theta l'est aussi.")


    def test_jointure_theta_fichier_vide_2(self):
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
        jt = jointure_theta(fichier1,
                            fichier2,
                            lambda tp: True) 
        self.assertEqual(list(jt),
                         [],
                         "Lorsque la seconde table est vide la jointure theta l'est aussi.")

    def test_jointure_theta_triviale(self):
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
        jt = jointure_theta(fichier1,
                            fichier2,
                            lambda tp: True)
        pc = produit_cartesien_fichier(fichier1, fichier2)
        self.assertEqual(list(jt),
                         list(pc),
                         "Avec une condition triviale, la jointure theta doit\
                         produire le même résultat qu'un produit cartésien.")

    def test_jointure_theta(self):
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
        jt = jointure_theta(fichier1,
                            fichier2,
                            lambda tp: tp['a'] == tp['e'] or
                            tp['c'] == tp['e'])
        self.assertEqual(list(jt),
                         [appariement(tp1, tp2) for tp1 in tbl1 for tp2 in tbl2
                          if tp1['a'] == tp2['e'] or
                          tp1['c'] == tp2['e']],
                         "La sémantique de la jointure n'est pas respectée.")

if __name__ == '__main__':
    unittest.main()
