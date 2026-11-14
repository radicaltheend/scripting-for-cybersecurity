word = input("Please enter a word: ")

chars = list(word)
print(chars)

reversed_word = ""
for c in chars:
    reversed_word = c + reversed_word

print(word)
print(reversed_word)

if word == reversed_word:
    print("palindrome")
else:
    print("not a palindrome")
