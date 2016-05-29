/*
 * Copyright (c) 2014, Oracle America, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *  * Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 *  * Neither the name of Oracle nor the names of its contributors may be used
 *    to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package com.mycompany;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import org.openjdk.jmh.infra.Blackhole;

import org.openjdk.jmh.annotations.*;

public class MyBenchmark {

    @State(Scope.Thread)
    public static class MyState {

        public static Map<Integer, List<String>> wordsByLength;
        public static Integer counter;
        public static Integer targetLength;

        @Setup(Level.Trial)
        public static void findGoodWords() {
            List<String> goodWords = new ArrayList<String>();
            try {
                Pattern p = Pattern.compile("^[abcdef]*$");
                BufferedReader br = new BufferedReader(new FileReader("/usr/share/dict/words"));
                String line;
                while ((line = br.readLine()) != null) {
                    if (line.length() > 2 && p.matcher(line).matches()) {
                        goodWords.add(line);
                    }
                }
                goodWords.add("a");
            }
            catch(Exception e) {}
            wordsByLength = goodWords.stream().collect(Collectors.groupingBy(w -> w.length()));
            counter = 0;
            targetLength = 14;
        }
    }

    public static void solve(
        MyState state,
        int phraseLength,
        HashSet<String> usedWords)
    {
        for(int i=1; i<state.targetLength-phraseLength+1; i++) {
            List<String> candidates = state.wordsByLength.get(i);
            if (candidates == null) continue;
            for(String w: candidates) {
                if(!usedWords.contains(w)) {
                    if (phraseLength+i == state.targetLength) {
                        state.counter++;
                    } else {
                        usedWords.add(w);
                        solve(state, phraseLength+i, usedWords);
                        usedWords.remove(w);
                    }
                }
            }
        }
    }

    @Benchmark
    @Warmup(iterations=10, time=3, timeUnit=TimeUnit.SECONDS)
    public void testMethod(MyState state) {
        state.counter = 0;
        solve(state, 0, new HashSet<String>());
        // System.out.printf("Exiting with state %d...\n", state.counter);
        // System.out.flush();
        // if (!state.counter.equals(3020796)) {
        //     System.exit(1);
        // }
    }

}
