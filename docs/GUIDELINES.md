# GUIDELINES for AI's

Main Documents:

- SPECS-IN-COMMON.md - Specs shared with plannies-mate
- SPECS.MD - specs specific to this project
- IMPLEMENTATION.md - implementation decisions made
- GUIDELINES.md - Guidelines for AIs and Developers (shared with plannies-mate) - This document
- README.md is - setup and usage by the Developer

# Goals

I am an experienced Aussie Developer with a quirky sense of humour, I want clean subtle
humour in wording - friendly without being "in your face"! I value well-thought-out succinct code that is clear. KISS
rules apply.

## AI Interaction Principles

- Respect existing working code style and design decisions
- Minimize unnecessary rewrites
- Prioritize incremental improvements
- Ask clarifying questions before major changes
- Solve problems with the smallest possible intervention
- When in doubt, propose the least invasive solution

## AI Development Approach

### Understanding Requirements

- Always check SPEC.md and related `SPEC-*.md` and `IMPLEMENTATION-*.md` files first for exact requirements
- Don't make assumptions about data formats or processing rules
- Ask for clarification if requirements seem ambiguous
- Remember that simpler is usually better

## Code Quality Principles

- Write code that is immediately understandable
- Prioritize clarity over cleverness
- Comments explain "why", code explains "how"
- Keep functions short and focused (under 20 lines)
- Keep files focused on a single clear responsibility (under 200 lines)
- Choose readable variable names over terse ones
- Write code optimized for developer efficiency and understanding, follow Knuth's recommendation:
    - In Donald Knuth's paper "Structured Programming With Go To Statements", he wrote:
      "Programmers waste enormous amounts of time thinking about, or worrying about,
      the speed of noncritical parts of their programs, and these attempts at efficiency actually
      have a strong negative impact when debugging and maintenance are considered.
      We should forget about small efficiencies, say about 97% of the time:
      premature optimization is the root of all evil.
      Yet we should not pass up our opportunities in that critical 3%."
- When in doubt, err on the side of simplicity and clarity
- Value code that communicates intent clearly over clever optimizations
- Measure efficiency by how quickly another developer can understand and modify the code

## Best Practices

Follow [Agile](https://www.agilealliance.org/agile101/) best practices including as elaborated in

* [The Agile Samurai](https://www.pragprog.com/titles/jtrap/the-agile-samurai/)
    * [Inception Deck](https://agilewarrior.wordpress.com/2010/11/06/the-agile-inception-deck/)

Language specific guidelines:

* [Ruby Style Guide](https://github.com/rubocop/ruby-style-guide)
* [PEP 8 – Style Guide for Python Code](https://peps.python.org/pep-0008/)
* [Ansible for Devops](https://docs.ansible.com/ansible/latest/playbook_guide/index.html)

## AI Behavioral Safeguards

- Code is for communication between developers, not just instructions for the CPU
- Prefer confirming understanding over ending up rewriting
- Demonstrate your reasoning when proposing changes / alternative solutions
- Prefer the simpler minimal path to solving the problem
- Explicitly state why a change or alternative solution is necessary
- Focus primarily on completing the requested task.
    - If uncertain, ask clarifying questions first before proceeding
    - When you have suggestions beyond the scope of the request,
      present them as succinct bullet points alongside your implementation.
      This allows me to decide whether to:
        - Interrupt the current work to discuss your suggestion
        - Note it for later consideration
        - Or set it aside
- Don't [Write code you don't need!](https://daedtech.com/dont-write-code-you-dont-need/) it adds extra technical debt
  and is a code smell, not a benefit!
- When suggesting improvements, separate them clearly from the requested implementation

## Defensive Programming Principles

- Treat all external input as potentially hostile and/or broken
- Validate and sanitize inputs rigorously
- Fail fast and explicitly when assumptions are violated
- Use language-specific safety mechanisms
- Prefer restrictive parsing over permissive methods
- Prioritize code clarity over excessively detailed defensive checks
- Remember: Code is a communication tool, not just machine instructions

### Code Development

- Focus on one component at a time
- Avoid over-engineering or adding unnecessary complexity
- Pay special attention to resource cleanup and error handling
- Consider edge cases but don't over-optimize prematurely

### Process Management

- Handle external processes carefully (initialization, cleanup)
- Use proper error handling for system calls
- Ensure resources are released appropriately
- Consider signal handling where appropriate

### Data Processing

- Follow specified rules exactly - don't add "improvements" without discussion
- Watch for assumptions about input formats
- Be careful with memory usage for larger datasets
- Consider rate limits when accessing external services

### Testing & Development

- Use limit parameters during development when available
- Test with small datasets first
- Verify output formats carefully
- Check resource cleanup during normal and error conditions
- Use VCR / Webmock to record / mock external resources, Use REAL internal objects - don't mock them (Test reality, NOT
  a mock-up of what we hope is there!)

## Common AI Pitfalls to Avoid

- Adding complexity that wasn't requested
- Making assumptions about "standard" ways to process data
- Trying to optimize too early
- Missing cleanup of external resources
- Over-commenting obvious code
- Under-documenting complex logic - mainly a problem with obscuring what the code is doing with fluff comments rather
  than actually explaining why, and making sure code explain how abd what it is doing
- Losing focus on the primary request by pursuing tangential improvements
- Prioritizing computer efficiency over developer comprehension

## Communication

- Ask questions when requirements are unclear
- Propose simplifications when possible
- Identify potential issues early
- Be explicit about implementation trade-offs

Remember: The AI's role is to implement the specified requirements accurately and simply, not to enhance them without
discussion.
