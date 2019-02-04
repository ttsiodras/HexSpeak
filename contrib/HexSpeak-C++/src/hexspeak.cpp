#include <stdint.h>

#include <iostream>
#include <list>
#include <string>
#include <regex>
#include <fstream>
#include <vector>
#include <chrono>
#include <algorithm>

uint32_t counter = 0;

using namespace std;

list<string> getGoodWords(const string& filename, const string& letters)
{
    list<string> goodWords;
    regex pattern("^["+letters+"]*$");
    ifstream infile(filename);
    string line;
    while(getline(infile, line)) {
        if (line.length() > 2 && regex_match(line, pattern))
            goodWords.push_back(line);
    }
    goodWords.push_back("a");
    return goodWords;
}

void solve(
    // Use dirty tricks :-) - intern strings (i.e. use their
    // insides (const char*) instead of actual 'wrapper'
    // string instances, use vectors instead of
    // lists for much better cache coherency (so that
    // algorithm::find ends up searching tiny cache lines!), etc.
    //
    // In plain words: BEEP BEEP (Java falls in pieces :-)
    //
    const vector<vector<const char *>>& wordsByLength,
    int targetLength,
    int phraseLength,
    vector<const char *>& usedWords)
{
    for(int i=1; i<targetLength-phraseLength+1; i++) {
        for(const auto &w: wordsByLength[i]) {
            if(find(usedWords.begin(), usedWords.end(), w) == usedWords.end()) {
                if (phraseLength+i == targetLength) {
                    counter++;
                } else {
                    usedWords.push_back(w);
                    solve(wordsByLength, targetLength, phraseLength+i, usedWords);
                    usedWords.pop_back();
                }
            }
        }
    }
}

int main(int argc, char *argv[])
{
    const string targetLengthStr = (argc<2)?"14":argv[1];
    const uint32_t targetLength = atoi(targetLengthStr.c_str());
    const string letters = (argc<3)?"abcdef":argv[2];
    const string wordsFilename = (argc<4)?"../../words":argv[3];
    auto goodWords = getGoodWords(wordsFilename, letters);
    vector<vector<const char *>> wordsByLength(128);
    for(const auto& word: goodWords)
        wordsByLength[word.length()].push_back(word.c_str());
    for(int i=0; i<10; i++) {
        counter = 0;
        auto usedWords = vector<const char *>();
        auto startTime = chrono::steady_clock::now();
        solve(wordsByLength, targetLength, 0, usedWords);
        auto endTime = chrono::steady_clock::now();
        cout << counter << " in " << chrono::duration<double, milli>(endTime-startTime).count()  << " ms.\n";
    }
    cout << endl;
}
