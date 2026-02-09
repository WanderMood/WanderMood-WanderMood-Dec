#!/bin/bash
# Script to verify .env file configuration

echo "🔍 Checking .env file..."
echo ""

if [ ! -f .env ]; then
    echo "❌ .env file does not exist!"
    echo "   Run: cp env.template .env"
    exit 1
fi

echo "✅ .env file exists"
echo ""

# Check for required variables
REQUIRED_VARS=("SUPABASE_URL" "SUPABASE_ANON_KEY")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    # Try multiple patterns to handle different line endings and formats
    if ! grep -qE "^${var}=|^${var} =|${var}=" .env 2>/dev/null; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "❌ Missing required variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    echo ""
    echo "Expected format:"
    echo "SUPABASE_URL=https://oojpipspxwdmiyaymldo.supabase.co"
    echo "SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    exit 1
fi

echo "✅ All required variables found"
echo ""

# Check if URL is correct
if grep -q "oojpipspxwdmiyaymldo.supabase.co" .env 2>/dev/null; then
    echo "✅ Supabase URL is correct"
else
    echo "⚠️  Supabase URL might be incorrect"
    echo "   Expected: https://oojpipspxwdmiyaymldo.supabase.co"
fi

echo ""
echo "📋 Current .env file contents:"
echo "---"
cat .env
echo "---"
echo ""
echo "✅ Verification complete!"
