def carres(n):
  res = []
  for i in range(n):
    print("foo")
    res.append(i*i)
  return res

def flux_carres_bis(n):
  for i in range(n):
    print("bar")
    yield i*i

for c in carres(10):
  print(c)

for c in flux_carres_bis(10):
  print(c)