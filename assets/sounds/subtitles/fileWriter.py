# Vars
punctuation = [".",",","!","?","-","…"]
sentences = [""]
count = 0
loopCount = 0
fileName = "eng/maxmode"
jsonContents = "{\n"

# File Content
file = open(fileName + ".txt","r")
contents = file.read()
contents = contents.replace("â€™","'")
file.close()

# Converts contents to individual lines
for i in contents:
    if not (i in punctuation):
        sentences[count] += i
    else:
        sentences[count] += i
        sentences.append("")
        count += 1
    loopCount += 1

# Gets rid of spaces at start of sentences
for i in range(len(sentences)):
    if sentences[i].startswith(" "):
        sentences[i] = sentences[i][1:]

# Formats the sentences into a JSON file
for i in sentences:
    if len(i) != 0:
        jsonContents += '\t"": "' + i + '",\n'
jsonContents = jsonContents[:-2]
jsonContents += "\n}"

# Creates the JSON file and saves the formatted text to it
file = open(fileName + ".json","w")
file.write(jsonContents)
file.close()