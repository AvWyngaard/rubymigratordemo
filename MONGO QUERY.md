# MongoDB Data Organization and Querying with Ruby

## Table of Contents
1. [MongoDB Data Structure](#mongodb-data-structure)
2. [How Data is Organized](#how-data-is-organized)
3. [Querying in MongoDB Shell](#querying-in-mongodb-shell)
4. [Querying with Ruby](#querying-with-ruby)
5. [Common Query Patterns](#common-query-patterns)
6. [Advanced Queries](#advanced-queries)

---

## 1. MongoDB Data Structure

### Database → Collections → Documents

```
MongoDB Server
├── Database: medical_practice_demo
│   ├── Collection: patients
│   │   ├── Document (patient 1)
│   │   ├── Document (patient 2)
│   │   └── Document (patient 3)
│   ├── Collection: appointments
│   │   ├── Document (appointment 1)
│   │   └── Document (appointment 2)
│   └── Collection: practitioners
│       └── Document (practitioner 1)
└── Database: another_database
    └── ...
```

### Terminology Comparison

| MongoDB | Relational DB | Ruby |
|---------|---------------|------|
| Database | Database | - |
| Collection | Table | Array |
| Document | Row | Hash |
| Field | Column | Key-Value Pair |
| _id | Primary Key | Unique Identifier |

---

## 2. How Data is Organized

### Documents (Like JSON)

A document is basically a hash/dictionary:

```javascript
{
  "_id": ObjectId("507f1f77bcf86cd799439011"),  // Auto-generated ID
  "patient_id": "550e8400-e29b-41d4-a716-446655440000",
  "first_name": "John",
  "last_name": "Doe",
  "date_of_birth": ISODate("1985-06-15"),
  "age": 38,
  "allergies": ["Penicillin", "Peanuts"],        // Array
  "address": {                                     // Nested document
    "street": "123 Main St",
    "city": "Boston",
    "state": "MA"
  }
}
```

### Key Features

**1. Schema-less (Flexible)**
- Documents in the same collection can have different fields
- No need to define schema upfront

```javascript
// Patient 1
{ "first_name": "John", "last_name": "Doe", "age": 30 }

// Patient 2 - different fields!
{ "first_name": "Jane", "email": "jane@example.com", "allergies": ["Latex"] }
```

**2. Nested Documents**
```javascript
{
  "patient_id": "123",
  "address": {                    // Nested object
    "street": "123 Main St",
    "city": "Boston"
  }
}
```

**3. Arrays**
```javascript
{
  "patient_id": "123",
  "allergies": ["Penicillin", "Peanuts"],    // Array of strings
  "medications": [                            // Array of objects
    { "name": "Aspirin", "dosage": "100mg" },
    { "name": "Lisinopril", "dosage": "10mg" }
  ]
}
```

**4. Auto-generated _id**
- Every document gets a unique `_id` field
- ObjectId: 12-byte identifier (timestamp + machine + process + counter)
- You can provide your own _id if you want

---

## 3. Querying in MongoDB Shell

First, let's look at how to query in the MongoDB shell, then we'll do it in Ruby.

### Connect to MongoDB Shell

```bash
# Modern MongoDB (v5+)
mongosh medical_practice_demo

# Older MongoDB
mongo medical_practice_demo
```

### Basic Queries

**Find all documents:**
```javascript
db.patients.find()
```

**Find with condition:**
```javascript
// Find patients with first_name "John"
db.patients.find({ first_name: "John" })

// Find patients with age greater than 30
db.patients.find({ age: { $gt: 30 } })
```

**Find one document:**
```javascript
db.patients.findOne({ first_name: "John" })
```

**Count documents:**
```javascript
db.patients.countDocuments()
db.patients.countDocuments({ age: { $gt: 30 } })
```

### Query Operators

```javascript
// Comparison
$eq     // Equal to
$ne     // Not equal to
$gt     // Greater than
$gte    // Greater than or equal
$lt     // Less than
$lte    // Less than or equal
$in     // In array
$nin    // Not in array

// Examples:
db.patients.find({ age: { $gte: 18 } })
db.patients.find({ blood_type: { $in: ["A+", "B+"] } })
db.patients.find({ first_name: { $ne: null } })
```

### Logical Operators

```javascript
// AND (implicit)
db.patients.find({ 
  first_name: "John", 
  age: { $gt: 30 } 
})

// OR
db.patients.find({ 
  $or: [
    { first_name: "John" },
    { first_name: "Jane" }
  ]
})

// NOT
db.patients.find({ 
  age: { $not: { $lt: 18 } } 
})
```

### Nested Field Queries

```javascript
// Query nested fields with dot notation
db.patients.find({ "address.city": "Boston" })
db.patients.find({ "address.state": "MA" })
```

### Array Queries

```javascript
// Find patients with "Penicillin" in allergies
db.patients.find({ allergies: "Penicillin" })

// Find patients with ANY allergies
db.patients.find({ allergies: { $exists: true, $ne: [] } })

// Find patients with NO allergies
db.patients.find({ $or: [
  { allergies: { $exists: false } },
  { allergies: [] }
]})
```

---

## 4. Querying with Ruby

Now let's do the same queries in Ruby!

### Setup

```ruby
require 'mongo'

# Connect to database
client = Mongo::Client.new('mongodb://localhost:27017', database: 'medical_practice_demo')

# Get a collection
patients = client[:patients]
```

### Basic Queries

**Find all documents:**
```ruby
# Returns a cursor (lazy iterator)
cursor = patients.find()

# Convert to array
all_patients = patients.find().to_a

# Iterate
patients.find().each do |patient|
  puts patient['first_name']
end
```

**Find with condition:**
```ruby
# Find patients named "John"
johns = patients.find(first_name: "John").to_a

# Find patients over 30
older_patients = patients.find(age: { '$gt' => 30 }).to_a
```

**Find one document:**
```ruby
john = patients.find(first_name: "John").first
# or
john = patients.find_one(first_name: "John")
```

**Count documents:**
```ruby
total = patients.count()
# or
total = patients.count_documents()

# Count with filter
johns_count = patients.count_documents(first_name: "John")
```

### Query Operators in Ruby

```ruby
# Greater than
patients.find(age: { '$gt' => 30 })

# Greater than or equal
patients.find(age: { '$gte' => 18 })

# Less than
patients.find(age: { '$lt' => 65 })

# Not equal
patients.find(first_name: { '$ne' => nil })

# In array
patients.find(blood_type: { '$in' => ["A+", "B+", "O+"] })

# Not in array
patients.find(blood_type: { '$nin' => ["AB+", "AB-"] })

# Exists
patients.find(email: { '$exists' => true })

# Does not exist or is null
patients.find(email: { '$exists' => false })
```

### Logical Operators in Ruby

```ruby
# AND (implicit)
patients.find(
  first_name: "John",
  age: { '$gt' => 30 }
)

# OR
patients.find(
  '$or' => [
    { first_name: "John" },
    { first_name: "Jane" }
  ]
)

# AND with OR
patients.find(
  age: { '$gte' => 18 },
  '$or' => [
    { first_name: "John" },
    { last_name: "Doe" }
  ]
)

# NOT
patients.find(
  age: { '$not' => { '$lt' => 18 } }
)
```

### Nested Field Queries in Ruby

```ruby
# Query nested fields with dot notation
patients.find('address.city' => "Boston")
patients.find('address.state' => "MA")

# Multiple nested conditions
patients.find(
  'address.city' => "Boston",
  'address.state' => "MA"
)
```

### Array Queries in Ruby

```ruby
# Find patients with "Penicillin" allergy
patients.find(allergies: "Penicillin")

# Find patients with any allergies
patients.find(
  allergies: { 
    '$exists' => true, 
    '$ne' => [] 
  }
)

# Find patients with NO allergies
patients.find(
  '$or' => [
    { allergies: { '$exists' => false } },
    { allergies: [] }
  ]
)

# Find patients with multiple specific allergies
patients.find(
  allergies: { '$all' => ["Penicillin", "Peanuts"] }
)
```

---

## 5. Common Query Patterns

### Pattern 1: Find and Process

```ruby
# Find all patients and print names
patients.find().each do |patient|
  puts "#{patient['first_name']} #{patient['last_name']}"
end
```

### Pattern 2: Find with Projection (Select Specific Fields)

```ruby
# Only get first_name and last_name
patients.find(
  { age: { '$gt' => 30 } },
  { projection: { first_name: 1, last_name: 1 } }
).each do |patient|
  puts patient
end

# Exclude fields (0 = exclude, 1 = include)
patients.find(
  {},
  { projection: { _id: 0, created_at: 0, updated_at: 0 } }
)
```

### Pattern 3: Sorting

```ruby
# Sort by age (ascending)
patients.find().sort(age: 1).to_a

# Sort by age (descending)
patients.find().sort(age: -1).to_a

# Sort by multiple fields
patients.find().sort(last_name: 1, first_name: 1).to_a
```

### Pattern 4: Limiting Results

```ruby
# Get first 10 patients
patients.find().limit(10).to_a

# Skip first 10, get next 10 (pagination)
patients.find().skip(10).limit(10).to_a

# Combine: filter, sort, limit
patients.find(age: { '$gte' => 18 })
        .sort(age: -1)
        .limit(5)
        .to_a
```

### Pattern 5: Complex Queries

```ruby
# Find patients in Boston with allergies
patients.find(
  'address.city' => "Boston",
  allergies: { '$exists' => true, '$ne' => [] }
).to_a

# Find patients over 30 OR with specific blood type
patients.find(
  '$or' => [
    { age: { '$gt' => 30 } },
    { blood_type: "O+" }
  ]
).to_a
```

---

## 6. Advanced Queries

### Aggregation Pipeline

For complex queries, use the aggregation pipeline:

```ruby
# Count patients by blood type
result = patients.aggregate([
  {
    '$group' => {
      _id: '$blood_type',
      count: { '$sum' => 1 }
    }
  },
  {
    '$sort' => { count: -1 }
  }
])

result.each do |doc|
  puts "Blood type #{doc['_id']}: #{doc['count']} patients"
end
```

### Join-like Operations (Lookup)

```ruby
# Get appointments with patient information
appointments = client[:appointments]

result = appointments.aggregate([
  {
    '$lookup' => {
      from: 'patients',
      localField: 'patient_id',
      foreignField: 'patient_id',
      as: 'patient_info'
    }
  },
  {
    '$limit' => 5
  }
])

result.each do |appointment|
  puts appointment
end
```

### Text Search

First, create a text index:
```ruby
# In MongoDB shell:
# db.patients.createIndex({ first_name: "text", last_name: "text" })

# Then search in Ruby:
patients.find(
  '$text' => { '$search' => "John" }
).to_a
```

### Regular Expressions

```ruby
# Find patients whose first name starts with "J"
patients.find(
  first_name: { '$regex' => '^J', '$options' => 'i' }
).to_a

# 'i' option = case insensitive

# Contains "son" anywhere in last name
patients.find(
  last_name: { '$regex' => 'son', '$options' => 'i' }
).to_a
```

---

## 7. Practical Examples for Your Data

### Example 1: Find Data Quality Issues

```ruby
require 'mongo'

client = Mongo::Client.new('mongodb://localhost:27017', 
                           database: 'medical_practice_demo')
patients = client[:patients]

puts "=== DATA QUALITY REPORT ==="
puts

# Find patients with missing emails
missing_emails = patients.count_documents(
  '$or' => [
    { email: nil },
    { email: "" },
    { email: "   " }
  ]
)
puts "Patients with missing emails: #{missing_emails}"

# Find duplicate SSNs
duplicates = patients.aggregate([
  {
    '$group' => {
      _id: '$ssn',
      count: { '$sum' => 1 }
    }
  },
  {
    '$match' => { count: { '$gt' => 1 } }
  }
])

puts "\nDuplicate SSNs:"
duplicates.each do |doc|
  puts "  SSN #{doc['_id']}: #{doc['count']} patients"
end

# Find patients with incomplete addresses
incomplete_addresses = patients.count_documents(
  '$or' => [
    { 'address.street' => nil },
    { 'address.city' => nil },
    { 'address.state' => nil },
    { 'address.zip' => nil }
  ]
)
puts "\nPatients with incomplete addresses: #{incomplete_addresses}"

# Find future dates of birth
future_dob = patients.count_documents(
  date_of_birth: { '$gt' => Date.today }
)
puts "Patients with future date of birth: #{future_dob}"
```

### Example 2: Find Appointments for a Patient

```ruby
# Get patient
patient = patients.find_one(first_name: "John", last_name: "Doe")

if patient
  # Get all appointments for this patient
  appointments = client[:appointments]
  patient_appointments = appointments.find(
    patient_id: patient['patient_id']
  ).sort(appointment_date: -1).to_a
  
  puts "Appointments for #{patient['first_name']} #{patient['last_name']}:"
  patient_appointments.each do |appt|
    puts "  #{appt['appointment_date']}: #{appt['appointment_type']}"
  end
else
  puts "Patient not found"
end
```

### Example 3: Find Practitioners with Most Appointments

```ruby
appointments = client[:appointments]

result = appointments.aggregate([
  {
    '$group' => {
      _id: '$practitioner_id',
      appointment_count: { '$sum' => 1 }
    }
  },
  {
    '$sort' => { appointment_count: -1 }
  },
  {
    '$limit' => 5
  }
])

puts "Top 5 Busiest Practitioners:"
result.each do |doc|
  practitioner = client[:practitioners].find_one(
    practitioner_id: doc['_id']
  )
  if practitioner
    puts "  Dr. #{practitioner['last_name']}: #{doc['appointment_count']} appointments"
  end
end
```

### Example 4: Export Filtered Data to JSON

```ruby
require 'json'

# Get all patients in Boston
boston_patients = patients.find('address.city' => "Boston").to_a

# Convert to JSON
json_data = JSON.pretty_generate(boston_patients)

# Save to file
File.write('boston_patients.json', json_data)

puts "Exported #{boston_patients.length} Boston patients to boston_patients.json"
```

### Example 5: Update Documents

```ruby
# Update one document
patients.update_one(
  { patient_id: "some-uuid" },
  { '$set' => { email: "newemail@example.com" } }
)

# Update multiple documents
patients.update_many(
  { email: nil },
  { '$set' => { email: "unknown@example.com" } }
)

# Add a field to all documents
patients.update_many(
  {},
  { '$set' => { verified: false } }
)
```

### Example 6: Delete Documents

```ruby
# Delete one document
patients.delete_one(patient_id: "some-uuid")

# Delete multiple documents
patients.delete_many(email: nil)

# Delete all documents in collection (careful!)
patients.delete_many({})
```

---

## 8. Complete Query Script Example

Here's a complete script you can run:

```ruby
#!/usr/bin/env ruby
require 'mongo'

# Connect
client = Mongo::Client.new('mongodb://localhost:27017', 
                           database: 'medical_practice_demo')

puts "=" * 60
puts "MONGODB DATA EXPLORATION"
puts "=" * 60

# 1. Count documents
puts "\n1. COLLECTION COUNTS:"
puts "   Patients: #{client[:patients].count()}"
puts "   Practitioners: #{client[:practitioners].count()}"
puts "   Appointments: #{client[:appointments].count()}"
puts "   Medications: #{client[:medications].count()}"

# 2. Sample documents
puts "\n2. SAMPLE PATIENT:"
patient = client[:patients].find().limit(1).first
puts "   Name: #{patient['first_name']} #{patient['last_name']}"
puts "   DOB: #{patient['date_of_birth']}"
puts "   Blood Type: #{patient['blood_type']}"

# 3. Query examples
puts "\n3. PATIENTS WITH ALLERGIES:"
with_allergies = client[:patients].find(
  allergies: { '$exists' => true, '$ne' => [] }
).limit(5)

with_allergies.each do |p|
  puts "   #{p['first_name']} #{p['last_name']}: #{p['allergies'].join(', ')}"
end

# 4. Aggregation
puts "\n4. APPOINTMENTS BY STATUS:"
result = client[:appointments].aggregate([
  {
    '$group' => {
      _id: '$status',
      count: { '$sum' => 1 }
    }
  },
  {
    '$sort' => { count: -1 }
  }
])

result.each do |doc|
  puts "   #{doc['_id']}: #{doc['count']}"
end

# 5. Nested query
puts "\n5. PATIENTS IN BOSTON:"
boston_count = client[:patients].count_documents('address.city' => "Boston")
puts "   Found #{boston_count} patients in Boston"

puts "\n" + "=" * 60
```

---

## Key Takeaways

1. **MongoDB organizes data**: Database → Collections → Documents
2. **Documents are like hashes**: Flexible, can have different fields
3. **Use dot notation**: Access nested fields with `'address.city'`
4. **Operators use strings**: `'$gt'`, `'$in'`, `'$exists'` etc.
5. **Cursors are lazy**: Use `.to_a` or `.each` to actually fetch data
6. **Chain methods**: `.find().sort().limit()`
7. **Aggregation for complex queries**: Use pipeline for joins, grouping, etc.

---

## Next Steps

1. **Practice querying** your data with the examples above
2. **Try the aggregation pipeline** for complex analysis
3. **Create indexes** for faster queries on fields you query often
4. **Explore the MongoDB Ruby driver docs**: https://www.mongodb.com/docs/ruby-driver/current/

Happy querying! 🚀