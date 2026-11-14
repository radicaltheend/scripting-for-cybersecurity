charset = ['f', 'a', 'b', 'c', 'j', 'i', 'e', '*', ')', '£', '2', '/', 's', 'o']
target = 'e'

for c in charset:
	if c == target:
		print("Found letter 'e'")
		break
	else:
		print("Not found")
