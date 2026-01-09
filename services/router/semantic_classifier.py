from typing import Literal
import re

# Simple stub classifier: replace with BERT/Rust semantic router later
class SemanticClassifier:
    """
    Classifies incoming prompts as 'easy' or 'hard' to optimize routing.
    - Easy → smaller model (Mistral-Small)
    - Hard → larger model (Llama-Large)
    """

    def __init__(self, complexity_threshold: int = 50):
        # Threshold = token length cutoff for easy vs hard
        self.threshold = complexity_threshold

    def classify(self, prompt: str) -> Literal["easy", "hard"]:
        """
        Classify prompt complexity.
        Currently uses:
        - Token length
        - Regex for math/code patterns
        """
        tokens = prompt.split()
        length = len(tokens)

        # Heuristic: long prompts → hard
        if length > self.threshold:
            return "hard"

        # Regex: math or code → hard
        if re.search(r"[=+\-*/]|def |class |SELECT |FROM ", prompt):
            return "hard"

        # Default → easy
        return "easy"


# Example usage
if __name__ == "__main__":
    classifier = SemanticClassifier(complexity_threshold=50)

    examples = [
        "Summarize this short paragraph.",
        "Write Python code to implement a binary search algorithm.",
        "Explain quantum entanglement in detail with math equations."
    ]

    for prompt in examples:
        label = classifier.classify(prompt)
        print(f"Prompt: {prompt}\n → Classified as: {label}\n")
