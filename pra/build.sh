#!/bin/bash
set -e
set -x

RED='\033[1;91m'
NC='033[0m'

echo -e "${RED}Repo checkout:${NC}"
rm -rf /opt/pdfalto
cd /opt/

git clone --recurse-submodules https://github.com/npospelov/pdfalto.git
cd /opt/pdfalto

echo -e "${RED}Build release:${NC}"
cd /opt/pdfalto
cmake -DCMAKE_BUILD_TYPE=Release CMakeLists.txt
make -j$(nproc)

echo -e "${RED}Build debug:${NC}"
cd /opt/pdfalto
rm -rf CMakeCache.txt
make clean
git clean -fd
cmake -DCMAKE_BUILD_TYPE=Debug CMakeLists.txt
make -j$(nproc)

echo -e "${RED}Build debug with sanitizers:${NC}"
cd /opt/pdfalto
rm -rf CMakeCache.txt
make clean
git clean -fd
export CC=afl-cc
export CXX=afl-c++
cmake -DCMAKE_BUILD_TYPE=Debug CMakeLists.txt
AFL_USE_ASAN=1 AFL_USE_UBSAN=1 make -j$(nproc)

rm -rf sanitizers_report.txt
for f in ../format-corpus/pdf-handbuilt-test-corpus/*.pdf; do ./pdfalto "$f" &>> sanitizers_report.txt || true; done
for f in ../format-corpus/pdf-handbuilt-test-corpus/*.pdf; do ./pdfalto -verbose -outline -annotation  "$f" &>> sanitizers_report.txt || true ; done
#for f in ../format-corpus/govdocs1-error-pdfs/error_set_2/*.pdf; do ./pdfalto "$f" &>> sanitizers_report.txt ||true; done
#for f in ../format-corpus/govdocs1-error-pdfs/error_set_2/*.pdf; do ./pdfalto -verbose -outline -annotation  "$f" &>> sanitizers_report.txt ||true; done
#for f in ../format-corpus/pdfCabinetOfHorrors/*.pdf; do ./pdfalto "$f" &>> sanitizers_report.txt ||true; done
#for f in ../format-corpus/pdfCabinetOfHorrors/*.pdf; do ./pdfalto -verbose -outline -annotation "$f" &>> sanitizers_report.txt ||true; done

echo -e "${RED}Build with coverage:${NC}"
cd /opt/pdfalto
rm -rf CMakeCache.txt
make clean
git clean -fd
export COV_BUILD_FLAGS="-O0 -g --coverage"
export CC=gcc
export CXX=g++
export CFLAGS="$COV_BUILD_FLAGS"
export CXXFLAGS="$COV_BUILD_FLAGS"
export LDFLAGS="$COV_BUILD_FLAGS"
cmake -DCMAKE_BUILD_TYPE=Debug CMakeLists.txt
make -j$(nproc)
unset COV_BUILD_FLAGS

rm -rf sanitizers_report.txt
for f in ../format-corpus/pdf-handbuilt-test-corpus/*.pdf; do ./pdfalto "$f" || true; done
for f in ../format-corpus/pdf-handbuilt-test-corpus/*.pdf; do ./pdfalto -verbose -outline -annotation "$f"||true; done
#for f in ../format-corpus/govdocs1-error-pdfs/error_set_2/*.pdf; do ./pdfalto "$f"||true; done
#for f in ../format-corpus/govdocs1-error-pdfs/error_set_2/*.pdf; do ./pdfalto -verbose -outline -annotation "$f"||true; done
#for f in ../format-corpus/pdfCabinetOfHorrors/*.pdf; do ./pdfalto "$f"||true; done
#for f in ../format-corpus/pdfCabinetOfHorrors/*.pdf; do ./pdfalto -verbose -outline -annotation "$f"||true; done

lcov -c -d . -o main_coverage.info
genhtml --ignore-errors source -o report main_coverage.info

lcov -c -d . -o main_coverage_b.info --rc lcov_branch_coverage=1
genhtml --ignore-errors source -o report_b main_coverage_b.info --rc lcov_branch_coverage=1
