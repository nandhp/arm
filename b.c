int main() { 
  asm("b foo\nfoo:");
  return 0;
}
