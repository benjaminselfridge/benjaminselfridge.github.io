cp model-checking/images/*.png images

pandoc -s --toc --metadata title="Model Checking in Haskell, Part 1: Transition Systems and Invariants" -f markdown+lhs -t html -c ../assets/pandoc.css -o posts/2022-05-10-model-checking-1.html model-checking/src/ModelChecking1.lhs
pandoc -s --toc --metadata title="Model Checking in Haskell, Part 2: From Programs to Transition Systems" -f markdown+lhs -t html -c ../assets/pandoc.css -o posts/2022-06-15-model-checking-2.html model-checking/src/ModelChecking2.lhs
