list = [789, -4, 10,20,30, 50,60, 80,23]
highest = list[0]
lowest = list[0]
for num in list:
	if num > highest:
		highest = num
	if num < lowest:
		lowest = num
print("Highest: ", highest)
print("Lowest: ", lowest)
