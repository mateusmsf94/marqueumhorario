# GitHub Copilot Code Review Instructions

## 👋 Purpose
This document instructs GitHub Copilot how to perform code reviews on pull requests in this repository.

## ✅ Review Goals
When reviewing a pull request, focus on the following:

1. **Code Quality**
   - Ensure clean, readable, and maintainable code
   - Flag unused variables, unnecessary logic, or poor naming
   - Recommend better structure or idioms when possible

2. **Correctness**
   - Check for logical correctness and potential bugs
   - Ensure all edge cases are handled
   - Validate that the code does what it's supposed to do

3. **Security**
   - Identify and flag any potential security vulnerabilities
   - Look for unescaped input, unsafe data handling, or injection points

4. **Performance**
   - Suggest optimizations when appropriate
   - Flag inefficient or unnecessary operations

5. **Testing**
   - Confirm that the code is tested properly
   - Suggest additional tests for edge cases
   - Check for missing or weak test coverage

6. **Documentation**
   - Ensure meaningful code comments and documentation where needed
   - Recommend improvements for readability or developer understanding

## 🤖 Copilot's Tone
- Be professional, concise, and constructive
- Use bullet points for clarity
- Suggest improvements, don't just point out flaws

## Example Review Comments

✅ Good:
- "Consider renaming `x` to something more descriptive, like `user_count`."
- "You could simplify this logic using `Enumerable#any?` instead of a manual loop."

🚫 Avoid:
- "This is bad."
- Vague or overly critical language

## 🚨 Special Considerations
- This repository uses **Ruby on Rails** — follow Rails conventions and best practices
- Prioritize **security and performance** in controller and model layers
- Ensure background jobs and async tasks are well-structured and fault-tolerant


