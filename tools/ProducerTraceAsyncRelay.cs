using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;

// Keeps child stderr/stdout writes off the filesystem path. If log-file I/O
// stalls, the bounded queue drops excess lines instead of blocking the game.
public static class ProducerTraceAsyncRelay
{
    private sealed class LogLine
    {
        public readonly bool IsError;
        public readonly string Text;
        public LogLine(bool isError, string text) { IsError = isError; Text = text; }
    }

    public sealed class Result
    {
        public int ExitCode { get; internal set; }
        public long DroppedStdoutLines { get; internal set; }
        public long DroppedStderrLines { get; internal set; }
        public bool WriterStopped { get; internal set; }
        public string WriterError { get; internal set; }
    }

    private static BlockingCollection<LogLine> queue;
    private static Thread writerThread;
    private static string stdoutPath;
    private static string stderrPath;
    private static long droppedStdout;
    private static long droppedStderr;
    private static string writerError;

    public static Process Start(string executable, string workingDirectory,
        string stdoutFile, string stderrFile, int queueCapacity)
    {
        if (queueCapacity < 256) throw new ArgumentOutOfRangeException("queueCapacity");

        queue = new BlockingCollection<LogLine>(queueCapacity);
        stdoutPath = stdoutFile;
        stderrPath = stderrFile;
        droppedStdout = 0;
        droppedStderr = 0;
        writerError = null;

        Process process = new Process();
        process.StartInfo = new ProcessStartInfo
        {
            FileName = executable,
            WorkingDirectory = workingDirectory,
            UseShellExecute = false,
            CreateNoWindow = false,
            WindowStyle = ProcessWindowStyle.Normal,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        };
        process.OutputDataReceived += delegate(object sender, DataReceivedEventArgs e)
        {
            Enqueue(false, e.Data);
        };
        process.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs e)
        {
            Enqueue(true, e.Data);
        };

        writerThread = new Thread(WriteLoop);
        writerThread.IsBackground = true;
        writerThread.Name = "ProducerTrace log relay";
        writerThread.Start();

        try
        {
            if (!process.Start()) throw new InvalidOperationException("ProducerTrace did not start.");
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();
            return process;
        }
        catch
        {
            queue.CompleteAdding();
            writerThread.Join(1000);
            process.Dispose();
            throw;
        }
    }

    private static void Enqueue(bool isError, string text)
    {
        if (text == null) return; // EndOfStream notification.
        if (queue.TryAdd(new LogLine(isError, text))) return;
        if (isError) Interlocked.Increment(ref droppedStderr);
        else Interlocked.Increment(ref droppedStdout);
    }

    private static void WriteLoop()
    {
        StreamWriter stdout = null;
        StreamWriter stderr = null;
        try
        {
            stdout = new StreamWriter(stdoutPath, false, new UTF8Encoding(false));
            stderr = new StreamWriter(stderrPath, false, new UTF8Encoding(false));
            DateTime lastFlush = DateTime.UtcNow;
            int pending = 0;
            LogLine line;
            while (!queue.IsCompleted)
            {
                if (queue.TryTake(out line, 200))
                {
                    (line.IsError ? stderr : stdout).WriteLine(line.Text);
                    pending++;
                }

                if (pending >= 128 || (pending > 0 &&
                    (DateTime.UtcNow - lastFlush).TotalMilliseconds >= 250))
                {
                    stdout.Flush();
                    stderr.Flush();
                    pending = 0;
                    lastFlush = DateTime.UtcNow;
                }
            }

            while (queue.TryTake(out line))
                (line.IsError ? stderr : stdout).WriteLine(line.Text);
            stdout.Flush();
            stderr.Flush();
        }
        catch (Exception ex)
        {
            writerError = ex.GetType().FullName + ": " + ex.Message;
            // Keep draining the child's pipes through the bounded queue even if
            // a log file cannot be written. The child must not wait on disk I/O.
            LogLine ignored;
            while (!queue.IsCompleted)
                queue.TryTake(out ignored, 200);
            while (queue.TryTake(out ignored)) { }
        }
        finally
        {
            try { if (stdout != null) stdout.Dispose(); }
            catch (Exception ex) { if (writerError == null) writerError = ex.GetType().FullName + ": " + ex.Message; }
            try { if (stderr != null) stderr.Dispose(); }
            catch (Exception ex) { if (writerError == null) writerError = ex.GetType().FullName + ": " + ex.Message; }
        }
    }

    public static Result WaitForExit(Process process, int writerJoinMilliseconds)
    {
        process.WaitForExit();
        process.WaitForExit(); // Wait for asynchronous stdout/stderr events to drain.
        queue.CompleteAdding();
        bool writerStopped = writerThread.Join(writerJoinMilliseconds);
        return new Result
        {
            ExitCode = process.ExitCode,
            DroppedStdoutLines = Interlocked.Read(ref droppedStdout),
            DroppedStderrLines = Interlocked.Read(ref droppedStderr),
            WriterStopped = writerStopped,
            WriterError = writerError
        };
    }
}
