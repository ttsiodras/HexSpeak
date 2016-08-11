var g_words = {
    1: ['a'],
    2: [],
    3: ['ace', 'add', 'baa', 'bad', 'bed', 'bee', 'cab', 'cad', 'dab', 'dad', 'deb', 'def', 'ebb', 'eff', 'fab', 'fad', 'fed', 'fee'],
    4: ['abbe', 'abed', 'aced', 'babe', 'bade', 'bead', 'beef', 'cafe', 'caff', 'ceca', 'cede', 'dace', 'dded', 'dead', 'deaf', 'deed', 'face', 'fade', 'faff', 'feed'],
    5: ['added', 'baaed', 'ceded', 'decaf', 'ebbed', 'effed', 'faced', 'faded'],
    6: ['accede', 'beaded', 'bedded', 'beefed', 'cabbed', 'dabbed', 'decade', 'decaff', 'deeded', 'deface', 'efface', 'facade', 'faffed'],
    7: ['acceded', 'defaced', 'effaced']
}
var count = 0;

function solve_recursive_count(words, currentLen, used, targetLength) 
{
    for (var i=1; i<=targetLength-currentLen; i++) {
        var words_of_length_i = words[i] || [];
        for(var j=0; j<words_of_length_i.length; j++) {
            word = words_of_length_i[j];
            if (used.indexOf(word) === -1)
                if (i !== targetLength - currentLen) {
                    used.push(word);
                    solve_recursive_count(words, currentLen + i, used, targetLength)
                    used.pop();
                } else
                    count++;
        }
    }
}

for(var b=0; b<10; b++) {
    count = 0;
    var st = new Date().getTime();
    solve_recursive_count(g_words, 0, [], 14);
    var en = new Date().getTime();
    console.log(count + " in " + (en-st));
}
