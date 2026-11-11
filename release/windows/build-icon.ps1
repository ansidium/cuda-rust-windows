# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Rasterize the simple geometry in assets/chip-icon.svg at each native icon size.
# Each ICO frame is drawn independently rather than enlarged from a small bitmap.
Add-Type -AssemblyName System.Drawing
$frames = @()
foreach ($size in @(16, 20, 24, 32, 40, 48, 64, 128, 256)) {
    $bitmap = [Drawing.Bitmap]::new($size, $size)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.ScaleTransform($size / 64.0, $size / 64.0)
    $ink = [Drawing.ColorTranslator]::FromHtml('#1E1E1E')
    $pen = [Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml('#76B900'), 4)
    $pen.StartCap = $pen.EndCap = [Drawing.Drawing2D.LineCap]::Round
    foreach ($p in @(24, 32, 40)) {
        $graphics.DrawLine($pen, $p, 8, $p, 16)
        $graphics.DrawLine($pen, $p, 48, $p, 56)
        $graphics.DrawLine($pen, 8, $p, 16, $p)
        $graphics.DrawLine($pen, 48, $p, 56, $p)
    }
    $shape = [Drawing.Drawing2D.GraphicsPath]::new()
    $shape.AddArc(14, 14, 10, 10, 180, 90)
    $shape.AddArc(40, 14, 10, 10, 270, 90)
    $shape.AddArc(40, 40, 10, 10, 0, 90)
    $shape.AddArc(14, 40, 10, 10, 90, 90)
    $shape.CloseFigure()
    $dark = [Drawing.SolidBrush]::new($ink)
    $green = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#76B900'))
    $graphics.FillPath($dark, $shape)
    foreach ($x in @(23,34)) { foreach ($y in @(23,34)) { $graphics.FillRectangle($green, $x, $y, 7, 7) } }
    $memory = [IO.MemoryStream]::new()
    $bitmap.Save($memory, [Drawing.Imaging.ImageFormat]::Png)
    $frames += [pscustomobject]@{Size=$size; Bytes=$memory.ToArray()}
    if ($size -eq 256) { [IO.File]::WriteAllBytes((Join-Path $PSScriptRoot 'assets/chip-icon.png'), $memory.ToArray()) }
    $memory.Dispose(); $green.Dispose(); $dark.Dispose(); $shape.Dispose(); $pen.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
}
$stream = [IO.File]::Create((Join-Path $PSScriptRoot 'assets/chip-icon.ico'))
$writer = [IO.BinaryWriter]::new($stream)
try {
    $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$frames.Count)
    $offset = 6 + 16 * $frames.Count
    foreach ($frame in $frames) {
        $dimension = if ($frame.Size -eq 256) { 0 } else { $frame.Size }
        $writer.Write([byte]$dimension); $writer.Write([byte]$dimension)
        $writer.Write([byte]0); $writer.Write([byte]0)
        $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$frame.Bytes.Length); $writer.Write([uint32]$offset)
        $offset += $frame.Bytes.Length
    }
    foreach ($frame in $frames) { $writer.Write([byte[]]$frame.Bytes) }
} finally { $writer.Dispose(); $stream.Dispose() }
