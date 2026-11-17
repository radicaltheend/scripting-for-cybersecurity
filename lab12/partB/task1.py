a = [10, 20, 30, 20, 10, 50, 60, 40, 80, 50, 40]


final = []
for num in a:
	already = False
	for num2 in final:
		if num == num2:
			already = True
			break
	if not already:
		final.append(num)

print(final)
