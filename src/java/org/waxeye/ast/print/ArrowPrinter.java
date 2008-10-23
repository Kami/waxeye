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
package org.waxeye.ast.print;

import org.waxeye.ast.IAST;
import org.waxeye.ast.IChar;
import org.waxeye.ast.IEmpty;
import org.waxeye.ast.IASTVisitor;

/**
 * A class to print the AST with arrows.
 *
 * @param <E> The node types for the AST.
 *
 * @author Orlando Hill
 */
public final class ArrowPrinter <E extends Enum<?>> implements IASTVisitor<E>
{
    /** The level of indentation. */
    private int indentLevel;

    /**
     * Creates a new ArrowPrinter.
     */
    public ArrowPrinter()
    {
        this.indentLevel = 0;
    }

    /**
     * Prints the given tree.
     *
     * @param tree The tree to print.
     */
    public void print(final IAST<E> tree)
    {
        tree.acceptASTVisitor(this);
    }

    /** {@inheritDoc} */
    public void visitAST(final IAST<E> tree)
    {
        for (int i = 0; i < indentLevel - 1; i++)
        {
            System.out.print("    ");
        }

        if (indentLevel > 0)
        {
            System.out.print("->  ");
        }

        System.out.println(tree.getType());

        indentLevel++;

        for (IAST<E> child : tree.getChildren())
        {
            child.acceptASTVisitor(this);
        }

        indentLevel--;
    }

    /** {@inheritDoc} */
    public void visitEmpty(final IEmpty tree)
    {
    }

    /** {@inheritDoc} */
    public void visitChar(final IChar tree)
    {
        for (int i = 0; i < indentLevel - 1; i++)
        {
            System.out.print("    ");
        }

        if (indentLevel > 0)
        {
            System.out.print("|   ");
        }

        System.out.println(tree.getValue());
    }
}
