import java.io.BufferedReader;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

public class hexspeak {

    public static Integer counter = 0;

    public static List<String> getGoodWords() {
        List<String> goodWords = new ArrayList<String>();
        try {
            Pattern p = Pattern.compile("^[abcdef]*$");
            BufferedReader br = new BufferedReader(new FileReader("words"));
            String line;
            while ((line = br.readLine()) != null) {
                if (line.length() > 2 && p.matcher(line).matches()) {
                    goodWords.add(line);
                }
            }
            goodWords.add("a");
        }
        catch(Exception e) {}
        return goodWords;
    }

    public static void main(String[] args) {
        List<String> goodWords = getGoodWords();
        Map<Integer, List<String>> wordsByLength =
            goodWords.stream().collect(Collectors.groupingBy(w -> w.length()));
        for(int i=0; i<10; i++) {
            counter = 0;
            long startTime = System.nanoTime();
            solve(wordsByLength, 14, 0, new HashSet<String>());
            long endTime = System.nanoTime();
            System.out.printf("%d in %d ms.\n", counter, (endTime-startTime)/1000000);
        }
    }

    public static void solve(
        Map<Integer, List<String>> wordsByLength,
        int targetLength,
        int phraseLength,
        HashSet<String> usedWords)
    {
        for(int i=1; i<targetLength-phraseLength+1; i++) {
            List<String> candidates = wordsByLength.get(i);
            if (candidates == null) continue;
            for(String w: candidates) {
                if(!usedWords.contains(w)) {
                    if (phraseLength+i == targetLength) {
                        counter++;
                    } else {
                        usedWords.add(w);
                        solve(wordsByLength, targetLength, phraseLength+i, usedWords);
                        usedWords.remove(w);
                    }
                }
            }
        }
    }
}
