a = [2023, "setu", "Carlow"]
b = ["kilkenny road", "Co Carlow"]

a.extend(b)

print("After extension: ", a)

a.insert(2, "R93 V960")

print("After insertion: ", a)

a.pop(-1)

print("After removal: ", a)

print("Index of setu: ", a.index("setu"))

print("Amount of times setu appear: ", a.count("setu"))

c = a.copy()

print("Printing C... ", c)
