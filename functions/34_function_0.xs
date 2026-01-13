function function_0 {
  input {
    int days_mask
  }

  stack {
    api.lambda {
      code = """
          let mask = input.days_mask || 0;
          let count = 0;
          while (mask > 0) {
            count += (mask & 1);
            mask >>= 1;
          }
          return count;
        """
      timeout = 5
    } as $count
  }

  response = $count
}