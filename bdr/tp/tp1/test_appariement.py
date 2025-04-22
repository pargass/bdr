import types
import unittest

from tp1 import *
from disque import *


class test_produit_cartesien_fichier(unittest.TestCase):

    def test_appariement_attributs_dijoints(self):
        self.assertEqual(appariement({'a': 1,
                                      'b': 2},
                                     {'c': 3,
                                      'd': 4}),
                         {'a': 1, 'b': 2, 'c': 3, 'd': 4},
                         "La sémantique de l'appariement n'est pas respectée.")

    def test_appariement_attibuts_communs(self):
        self.assertEqual(appariement({'a': 1,
                                      'b': 2},
                                     {'b': 3,
                                      'c': 4}),
                         {'a': 1, 'b': 3, 'c': 4},
                         "La sémantique de l'appariement n'est pas respectée.")

    def test_appariement_vide_1(self):
        self.assertEqual(appariement({},
                                     {'a': 1,
                                      'b': 2}),
                         {'a': 1, 'b': 2},
                         "Le dictionnaire vide doit être un neutre à gauche d'appariement.")

    def test_appariement_vide_2(self):
        self.assertEqual(appariement({'a': 1,
                                      'b': 2},
                                     {}),
                         {'a': 1, 'b': 2},
                         "Le dictionnaire vide doit être un neutre à droite d'appariement.")



if __name__ == '__main__':
    unittest.main()
