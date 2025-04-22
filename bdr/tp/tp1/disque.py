import os

def byte_of_tuple(tp):
    """
    Renvoie la séquence d'octets représentant un tuple (i.e. un dictionnaire)
    sur disque.
    """
    return bytes(str(tp), 'utf-8')

def tuple_of_byte(bts):
    """
    Étant donnée une séquence d'octets lus sur le disque, la convertie en
    tuple.
    """
    return eval(bts.decode('utf-8'))

def mem_sur_disque(table, fichier):
    """
    Sauvegarde ~table~ sur disque dans le fichier ~fichier~.
    Chaque tuple occupe une ligne dans le fichier.
    """
    ls = bytes(os.linesep, 'utf-8')
    with open(fichier, 'wb') as f:
        for t in table:
            f.write(byte_of_tuple(t))
            f.write(ls)

def lire_sur_disque(fichier):
    """
    Lit une table sur disque dans le fichier ~fichier~.
    La table est renvoyée comme un flux de tuples.
    """
    with open(fichier, 'rb') as f:
        for l in f:
            yield tuple_of_byte(l)

def trouve_sur_disque(fichier, adresses):
    """
    Renvoie sous forme de flux les tuples contenus dans le fichier ~fichier~ qui
    sont désignés par les adresses physiques de la séquences ~adresses~.
    """
    with open(fichier, 'rb') as f:
        for adr in adresses:
            f.seek(adr, 0)
            yield tuple_of_byte(f.readline())

def index_fichier(fichier, attribut):
    """
    Renvoie un dictionnaire qui à chaque valeur de l'attribut ~attribut~
    associe la liste des adresses physiques des tuples représentés dans le fichiers,
    qui associe cette valeur à ~attribut~.
    """
    offset = 0
    index = {}
    with open(fichier,'rb') as f:
        for l in f:
            tp = tuple_of_byte(l)
            val = tp[attribut]
            if val in index:
                index[val].append(offset)
            else:
                index[val] = [offset]
            offset += len(l)
    return index
