# 1.1.0
  - Make the delivery method more reliable to failure by catching and
    logging exceptions when happen, like this LS is not going to break
    if something wrong happen, but is going to log it. Fixes #26 and #7
  - Randomize port in specs so they can run in parallel.
