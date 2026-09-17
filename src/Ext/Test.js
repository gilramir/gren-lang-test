// Runs a test's thunk, answering what it threw instead of ending the runner.
// It was the kernel's `_Test_runThunk`, which built the `Result` itself.

function runThunkWith(ok, err, thunk, arg) {
  try {
    return ok(thunk(arg));
  } catch (e) {
    return err(e.toString());
  }
}
