### question 1.1 

insert ('a','b') annulée car erreur de type


insert (5,5)
insert (6,6)
select T

ces trois instructions sont annulées car elles se trouvent entre un begin et un rollback

### question 1.2

situation A : la session 1 a lu la valeur 2 à chaque fois. Cela met en évidence que lorsque l'on a pas encore commit, les modifications ne sont pas visibles par les autres sessions.

### question 1.3

situation B : cette fois, la session 1 a lu la valeur 2 puis 3 après le commit de la session 2. Cela montre que les modifications sont visibles par les autres sessions après un commit. Cependant la session 1 n'a pas fini sa transaction et donc il y a un conflit car en lecture répétées, la session 1 a lu deux valeurs différentes.

### question 1.4

situation C : cette fois ci, après le commit de la session 2, la session 1 a lu 2 valeur 3 car la session 2 a insert puis commit. On a le même problème que précédemment, la session 1 n'a pas fini sa transaction et donc il y a un conflit.

### question 1.5

situation D : Cet ordonaancement n'est pas sériable car pas équivalent à une exécution en série. La session 1 bloque la délétion de la session 2.

### question 1.6

Situation B : nonrepetable read car update de la session 2
Situation C : phantom read car insert de la session 2
Situation D : serialization anomaly car la session 1 bloque la session 2

### question 1.7

voir tableau

### question 1.8

session 1 pose un verrou sur les lignes ou A = 3 et session 2 pose un verrou sur les lignes ou B = 2. lorsque la session 2 veut update la ligne ou A = 3, elle est bloquée car la session 1 a posé un verrou dessus. Il y a donc un interbloquage et un rollback.

### question 1.9

select for update est un select mais pose un verrou comme si c'était un update(bloque les instructions update de la session 2 s'il y a des lignesen communs avec celles véroullées par la session 1). c'est un verrou niveau table.

### question 1.10

voir tableau

### question 1.11

aucune des actions de la session 2 n'a été effectuée à cause de 'set transaction isolation level serializable ;' qui bloque les instructions de la session 2 tant que la session 1 n'a pas fini sa transaction.

### question 1.12

cette fois ci, la session 2 a été bloquée mais une fois que la session 1 a rollback, toutes les actions de la session 2 ont été effectuées.

### question 1.13

voir tableau

### question 2.1

problème lors de la verification, contrainte de clé circulaire. un ordinateur doit avoir un propriétaire et un propriétaire doit avoir un ordinateur.

### question 2.2

1. 






