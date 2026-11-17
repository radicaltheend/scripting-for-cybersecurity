sentence = "The quick brown fox jumps over the lazy dog"

words = sentence.split()
print("Words:", words)

long_words = []
for word in words:
    if len(word) > 3:
        long_words.append(word)

print("Longer than 3 characters:", long_words)
