/*
 * Waxeye Parser Generator
 * www.waxeye.org
 * Copyright (C) 2008 Orlando D. A. R. Hill
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
package org.waxeye.input;

/**
 * A class to represent the buffer to hold the input string.
 *
 * @author Orlando Hill
 */
public final class InputBuffer implements IParserInput
{
    /** The internal buffer. */
    private final char[] input;

    /** The current position in the buffer. */
    private int position;

    /** The size of the buffer. */
    private final int inputSize;

    /**
     * Creates a new InputBuffer for the given char[]. The position starts
     * at index 0.
     *
     * @param input The char[] to use for our buffer.
     */
    public InputBuffer(final char[] input)
    {
        this.input = input;
        this.position = 0;
        this.inputSize = input.length;

        assert invariants();
    }

    /**
     * Checks the invariants of the object.
     *
     * @return <code>true</code>.
     */
    private boolean invariants()
    {
        assert input != null;
        assert position >= 0 && position <= inputSize;

        return true;
    }

    /** {@inheritDoc} */
    public int consume()
    {
        if (position < inputSize)
        {
            return input[position++];
        }

        return EOF;
    }

    /** {@inheritDoc} */
    public int peek()
    {
        if (position < inputSize)
        {
            return input[position];
        }

        return EOF;
    }

    /** {@inheritDoc} */
    public int getPosition()
    {
        return position;
    }

    /**
     * Returns the inputSize.
     *
     * @return Returns the inputSize.
     */
    public int getInputSize()
    {
        return inputSize;
    }

    /**
     * Sets the position of the input buffer to the given value. If the value
     * given is less than 0 then the position is set to 0.
     *
     * @param position The position to set.
     */
    public void setPosition(final int position)
    {
        if (position < 0)
        {
            this.position = 0;
        }
        else
        {
            this.position = position;
        }
    }

    /** {@inheritDoc} */
    public boolean equals(final Object object)
    {
        if (this == object)
        {
            return true;
        }

        if (object != null && object.getClass() == this.getClass())
        {
            final InputBuffer b = (InputBuffer) object;

            if (input != b.input || position != b.position)
            {
                return false;
            }

            return true;
        }

        return false;
    }

    /** {@inheritDoc} */
    public int hashCode()
    {
        final int start = 17;
        final int mult = 37;
        int result = start;

        if (input != null)
        {
            for (char c : input)
            {
                result = mult * (result + c);
            }
        }

        result = mult * result + position;

        return Math.abs(result);
    }
}
