# Ruby Script Explanation - Medical Data Seeder

## Table of Contents
1. [Shebang and Dependencies](#shebang-and-dependencies)
2. [Configuration](#configuration)
3. [Database Connection](#database-connection)
4. [Helper Methods](#helper-methods)
5. [Data Generation](#data-generation)
6. [Ruby Syntax Basics](#ruby-syntax-basics)

---

## 1. Shebang and Dependencies

```ruby
#!/usr/bin/env ruby
```
- **Shebang line**: Tells the system to run this file with Ruby
- `#!` = shebang, `/usr/bin/env ruby` = find and use Ruby interpreter
- Allows you to run the file directly: `./seed_medical_data.rb` (after `chmod +x`)

```ruby
require 'mongo'
require 'faker'
require 'securerandom'
```
- **`require`**: Loads external libraries (gems)
- `'mongo'` = MongoDB driver for Ruby
- `'faker'` = Library for generating fake data
- `'securerandom'` = Built-in Ruby library for secure random values (like UUIDs)

---

## 2. Configuration

```ruby
DB_NAME = 'medical_practice_demo'
MONGO_URI = ENV['MONGO_URI'] || 'mongodb://localhost:27017'
```

### Constants
- **`DB_NAME`**: ALL_CAPS = Ruby convention for constants
- Constants shouldn't change during program execution

### Environment Variables
- **`ENV['MONGO_URI']`**: Reads environment variable
- `ENV` is a hash (dictionary) of all environment variables
- `['MONGO_URI']` accesses the value

### The `||` Operator (Logical OR)
```ruby
value = ENV['MONGO_URI'] || 'mongodb://localhost:27017'
```
- Reads: "Use ENV['MONGO_URI'] OR use default"
- If `ENV['MONGO_URI']` is `nil` or `false`, use the default
- Common Ruby pattern for default values

---

## 3. Database Connection

```ruby
client = Mongo::Client.new(MONGO_URI, database: DB_NAME)
```

### Ruby Object Creation
- **`Mongo::Client`**: The `::` is a scope resolution operator
  - `Mongo` = module (namespace)
  - `Client` = class inside the Mongo module
- **`.new`**: Creates a new instance of the class
- **Arguments**:
  - `MONGO_URI` = positional argument
  - `database: DB_NAME` = named argument (keyword argument)

### Method Calls
```ruby
client[:patients].drop
```
- `client[:patients]` = accesses the 'patients' collection
- `[]` = bracket notation (like hash/array access)
- `.drop` = method call to delete the collection

---

## 4. Helper Methods

```ruby
def maybe_error(value, error_rate = 0.15)
  return value if rand > error_rate
  
  case value
  when String
    case rand(5)
    when 0 then nil
    when 1 then ""
    # ...
    end
  when Integer
    rand(2) == 0 ? -1 : nil
  else
    nil
  end
end
```

### Method Definition
- **`def`**: Defines a method
- **`maybe_error`**: Method name (snake_case convention)
- **Parameters**:
  - `value` = required parameter
  - `error_rate = 0.15` = optional parameter with default value

### Early Return
```ruby
return value if rand > error_rate
```
- **`if` modifier**: Condition comes after the statement
- **`rand`**: Generates random float between 0 and 1
- If random > error_rate (85% of the time), return original value unchanged

### Case Statement (Switch)
```ruby
case value
when String
  # do something
when Integer
  # do something else
else
  # default
end
```
- Like `switch` in other languages
- Checks the type/value of `value`
- **`when String`**: If value is a String
- **`when Integer`**: If value is an Integer

### Ternary Operator
```ruby
rand(2) == 0 ? -1 : nil
```
- Format: `condition ? value_if_true : value_if_false`
- `rand(2)` generates 0 or 1
- If 0, return -1; otherwise return nil

### Implicit Return
```ruby
def example
  5 + 5  # This value is automatically returned
end
```
- Ruby returns the last evaluated expression
- No need for explicit `return` (though you can use it)

---

## 5. Data Generation

### Loops

```ruby
15.times do
  # code here
end
```
- **`.times`**: Integer method that repeats code
- Runs the block 15 times
- **`do...end`**: Defines a block (like a function body)

Alternative syntax:
```ruby
15.times { |i| puts i }  # Using curly braces for one-liners
```

### Blocks
```ruby
100.times do
  # This is a block
  # Code here runs 100 times
end
```
- Blocks are chunks of code passed to methods
- Can use `do...end` or `{...}`
- Convention: `do...end` for multi-line, `{}` for single-line

### Hashes (Dictionaries)

```ruby
practitioner = {
  practitioner_id: maybe_error(SecureRandom.uuid, 0.1),
  first_name: maybe_error(Faker::Name.first_name, 0.1),
  specialty: specialties.sample
}
```

### Symbol Keys
- **`:practitioner_id`**: Symbol (starts with colon)
- Symbols are immutable strings, more efficient for hash keys
- Modern syntax: `key: value` (equivalent to `:key => value`)

### Hash Access
```ruby
practitioner[:first_name]  # Access value by symbol key
```

---

## 6. Ruby Syntax Basics

### Arrays

```ruby
practitioners = []  # Empty array
practitioners << practitioner  # Push to array (append)
```

Alternative ways to add to arrays:
```ruby
practitioners.push(practitioner)  # Same as <<
practitioners = practitioners + [practitioner]  # Concatenation
```

### Array Methods

```ruby
specialties = ['General Practice', 'Cardiology', 'Pediatrics']
specialties.sample  # Returns random element
```

```ruby
patients.sample[:patient_id]
```
- `patients.sample` = get random patient hash
- `[:patient_id]` = access the patient_id value

### String Interpolation

```ruby
"MD-#{rand(100000..999999)}"
```
- **`#{...}`**: Evaluates Ruby code inside string
- Result: "MD-542891" (example)

```ruby
name = "John"
puts "Hello, #{name}!"  # Output: Hello, John!
```

### Ranges

```ruby
rand(100..999)  # Random number between 100 and 999 (inclusive)
rand(100...999) # Random number between 100 and 998 (exclusive)
```
- **`..`**: Inclusive range (includes end)
- **`...`**: Exclusive range (excludes end)

### Conditionals

```ruby
if condition
  # code
elsif other_condition
  # code
else
  # code
end
```

One-line conditionals:
```ruby
return value if rand > error_rate
do_something unless error_occurred
```

### Comparison Operators

```ruby
rand(10) < 2    # Less than
rand(10) == 0   # Equal to
rand(3) != 0    # Not equal to
```

### Logical Operators

```ruby
&&  # AND
||  # OR
!   # NOT
```

### Creating Arrays with Iteration

```ruby
Array.new(rand(1..3)) { "ICD10-#{rand(100..999)}.#{rand(0..9)}" }
```
- **`Array.new(size)`**: Creates array with specified size
- **Block after `new`**: Executes for each element
- Creates array like: `["ICD10-342.5", "ICD10-891.2"]`

### Random Selection

```ruby
['Spouse', 'Parent', 'Sibling'].sample  # Random element
[true, false].sample                     # Random boolean
```

### MongoDB-Specific Methods

```ruby
client[:practitioners].insert_many(practitioners)
```
- **`insert_many`**: Inserts multiple documents at once
- Takes an array of hashes
- More efficient than inserting one at a time

```ruby
client[:practitioners].count()
```
- **`count`**: Returns number of documents in collection

---

## Common Ruby Patterns in This Script

### 1. Guard Clause
```ruby
return value if rand > error_rate
```
Early exit if condition is met

### 2. Default Values with ||
```ruby
ENV['MONGO_URI'] || 'mongodb://localhost:27017'
```
Use environment variable or default

### 3. Conditional Assignment
```ruby
ssn = rand(10) < 2 ? "123-45-6789" : "#{rand(100..999)}-#{rand(10..99)}-#{rand(1000..9999)}"
```
Assign different values based on condition

### 4. Array Building
```ruby
practitioners = []
15.times do
  practitioners << practitioner
end
```
Build array by appending in loop

### 5. Nested Data Structures
```ruby
address: {
  street: "123 Main St",
  city: "Boston"
}
```
Hash containing hash (nested object)

---

## Key Differences from Other Languages

### No Semicolons
```ruby
puts "Hello"
x = 5
# No semicolons needed
```

### No Parentheses (Often Optional)
```ruby
puts "Hello"           # Can omit parentheses
puts("Hello")          # But can include them

maybe_error value, 0.1  # No parentheses
maybe_error(value, 0.1) # With parentheses
```

### Everything is an Object
```ruby
5.times { puts "Hi" }   # Even integers have methods
"hello".upcase          # => "HELLO"
[1, 2, 3].length        # => 3
```

### Symbols vs Strings
```ruby
:symbol   # Symbol - immutable, used as identifiers
"string"  # String - mutable, used for text
```

---

## Practice Examples

### Example 1: Understanding the maybe_error method
```ruby
# Without error (85% chance)
maybe_error("John", 0.15)  # => "John" (most likely)

# With error (15% chance)
maybe_error("John", 0.15)  # => nil, "", "   ", "JOHN", or "John123"
```

### Example 2: Building a patient
```ruby
patient = {
  first_name: "John",           # Symbol key
  last_name: "Doe",
  age: 45,
  allergies: ["Penicillin"],    # Array value
  address: {                     # Nested hash
    street: "123 Main St"
  }
}

# Access values
patient[:first_name]           # => "John"
patient[:address][:street]     # => "123 Main St"
```

### Example 3: Iteration patterns
```ruby
# Times loop
5.times { puts "Hello" }

# Each loop (iterate over array)
[1, 2, 3].each do |num|
  puts num * 2
end

# Map (transform array)
numbers = [1, 2, 3]
doubled = numbers.map { |n| n * 2 }  # => [2, 4, 6]
```

---

## Debugging Tips

### Print Statements
```ruby
puts "Value: #{variable}"        # Print to console
p variable                        # Pretty print (shows type info)
pp variable                       # Even prettier print
```

### Inspect Variables
```ruby
practitioners.length              # Number of elements
practitioners.first               # First element
practitioners.last                # Last element
practitioners.sample              # Random element
```

### Check Types
```ruby
value.class                       # Get object type
value.is_a?(String)              # Check if it's a String
value.nil?                        # Check if nil
value.empty?                      # Check if empty (arrays, strings)
```

---

## Common Mistakes to Avoid

### 1. Forgetting the colon for symbols
```ruby
# Wrong
patient = { first_name: "John" }  # This is okay
patient[first_name]                # ERROR: undefined variable

# Right
patient[:first_name]               # Use symbol to access
```

### 2. Confusing blocks and methods
```ruby
# Block (passed to a method)
5.times do
  puts "Hi"
end

# Method definition
def say_hi
  puts "Hi"
end
```

### 3. Not understanding implicit returns
```ruby
def add(a, b)
  a + b  # This is returned automatically
end

def broken_add(a, b)
  sum = a + b
  puts sum  # puts returns nil, so method returns nil!
end
```

---

## Next Steps

To learn more about this code:

1. **Experiment**: Change values and see what happens
   ```ruby
   15.times do  # Try: 3.times do
   ```

2. **Add debugging**: Insert print statements
   ```ruby
   puts "Creating practitioner: #{practitioner}"
   ```

3. **Try the Faker gem**:
   ```ruby
   puts Faker::Name.name
   puts Faker::Address.city
   puts Faker::Internet.email
   ```

4. **Explore MongoDB**:
   ```ruby
   # Add this at the end of the script
   first_patient = client[:patients].find.first
   puts first_patient
   ```

5. **Learn more Ruby**:
   - Official Ruby docs: https://ruby-doc.org/
   - Ruby Koans: http://rubykoans.com/
   - Try Ruby: https://try.ruby-lang.org/

---

## Summary

This script demonstrates:
- ✅ External library usage (gems)
- ✅ Hash creation (Ruby's objects/dictionaries)
- ✅ Array manipulation
- ✅ Iteration (loops)
- ✅ Methods with optional parameters
- ✅ Conditional logic
- ✅ Random data generation
- ✅ Database operations
- ✅ String interpolation

Ruby is designed to be readable and expressive - it should read almost like English!