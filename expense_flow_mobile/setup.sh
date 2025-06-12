#!/bin/bash

set -e  # Exit on error

# Print colorful messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Flutter is installed
check_flutter() {
  echo -e "${BLUE}Checking Flutter installation...${NC}"
  if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter is not installed or not in PATH.${NC}"
    echo -e "${YELLOW}Please install Flutter from https://flutter.dev/docs/get-started/install${NC}"
    exit 1
  fi

  flutter --version
  echo -e "${GREEN}Flutter is installed.${NC}"
}

# Check if Dart is installed
check_dart() {
  echo -e "${BLUE}Checking Dart installation...${NC}"
  if ! command -v dart &> /dev/null; then
    echo -e "${RED}Dart is not installed or not in PATH.${NC}"
    echo -e "${YELLOW}It should be installed with Flutter. Check your Flutter installation.${NC}"
    exit 1
  fi

  dart --version
  echo -e "${GREEN}Dart is installed.${NC}"
}

# Create .env.prod file if it doesn't exist
create_env_file() {
  echo -e "${BLUE}Checking for .env file...${NC}"
  if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    touch .env.prod
    echo "BASE_URL=http://localhost:8000/" >> .env.prod
    echo "API_KEY=your_api_key_here" >> .env.prod
    echo -e "${GREEN}.env file created. Please update with your actual API key.${NC}"
  else
    echo -e "${GREEN}.env file already exists.${NC}"
  fi
}

# Find localization package - removed since we're using the known path

# Get packages for all modules
get_packages() {
  echo -e "${BLUE}Getting packages for all modules...${NC}"

  # Main project
  echo -e "${YELLOW}Getting packages for root project...${NC}"
  flutter pub get

  # Domain package
  echo -e "${YELLOW}Getting packages for domain...${NC}"
  cd packages/domain
  flutter pub get
  cd ../..

  # Data package
  echo -e "${YELLOW}Getting packages for data...${NC}"
  cd packages/data
  flutter pub get
  cd ../..

  # Presentation package
  echo -e "${YELLOW}Getting packages for presentation...${NC}"
  cd packages/presentation
  flutter pub get
  cd ../..

  # Localization package
  echo -e "${YELLOW}Getting packages for localization...${NC}"
  cd packages/localization
  flutter pub get
  cd ../..

  echo -e "${GREEN}All packages retrieved successfully.${NC}"
}

# Generate localization files
generate_localizations() {
  echo -e "${BLUE}Generating localization files...${NC}"

  # Use the specific path provided
  if [ -f "packages/localization/generate_localizations.sh" ]; then
    cd packages/localization

    # Make the script executable if it's not already
    if [ ! -x "generate_localizations.sh" ]; then
      echo -e "${YELLOW}Making localization script executable...${NC}"
      chmod +x generate_localizations.sh
    fi

    # Run the localization script
    ./generate_localizations.sh

    cd ../..
    echo -e "${GREEN}Localization files generated successfully.${NC}"
  else
    echo -e "${RED}Error: Localization script not found at packages/localization/generate_localizations.sh${NC}"
    exit 1
  fi
}

# Run build_runner for code generation if needed
run_build_runner() {
  echo -e "${BLUE}Running build_runner for packages...${NC}"

  # Domain package
  echo -e "${YELLOW}Generating code for domain...${NC}"
  cd packages/domain
  flutter pub run build_runner build --delete-conflicting-outputs
  cd ../..

  # Data package
  echo -e "${YELLOW}Generating code for data...${NC}"
  cd packages/data
  flutter pub run build_runner build --delete-conflicting-outputs
  cd ../..

  # Presentation package
  echo -e "${YELLOW}Generating code for presentation...${NC}"
  cd packages/presentation
  flutter pub run build_runner build --delete-conflicting-outputs
  cd ../..

  echo -e "${GREEN}Code generation completed successfully.${NC}"
}

# Doctor check to make sure everything is set up properly
flutter_doctor() {
  echo -e "${BLUE}Running Flutter doctor...${NC}"
  flutter doctor -v
  echo -e "${GREEN}Flutter doctor check completed.${NC}"
}

# Clean the project (optional)
clean_project() {
  echo -e "${BLUE}Cleaning project...${NC}"
  flutter clean

  echo -e "${YELLOW}Cleaning domain...${NC}"
  cd packages/domain
  flutter clean
  cd ../..

  echo -e "${YELLOW}Cleaning data...${NC}"
  cd packages/data
  flutter clean
  cd ../..

  echo -e "${YELLOW}Cleaning presentation...${NC}"
  cd packages/presentation
  flutter clean
  cd ../..

  echo -e "${YELLOW}Cleaning localization...${NC}"
  cd packages/localization
  flutter clean
  cd ../..

  echo -e "${GREEN}Project cleaned successfully.${NC}"
}

# Main function
main() {
  echo -e "${BLUE}====== ExpenseFlow Project Setup ======${NC}"

  # Check if --clean flag is passed
  if [ "$1" == "--clean" ]; then
    clean_project
  fi

  check_flutter
  check_dart
  create_env_file
  get_packages
  generate_localizations
  run_build_runner
  flutter_doctor

  echo -e "${GREEN}====== Setup completed successfully! ======${NC}"
  echo -e "${YELLOW}You can now run the project with: flutter run${NC}"
}

# Call the main function with all args passed to the script
main "$@"