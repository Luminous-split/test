#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

static int	inside(int x, int y, int width, int height)
{
	return (x >= 0 && x < width && y >= 0 && y < height);
}

static int	count_neighbors(char *board, int x, int y,
		int width, int height)
{
	int	dx;
	int	dy;
	int	count;
	int	nx;
	int	ny;

	count = 0;
	dy = -1;
	while (dy <= 1)
	{
		dx = -1;
		while (dx <= 1)
		{
			if (!(dx == 0 && dy == 0))
			{
				nx = x + dx;
				ny = y + dy;
				if (inside(nx, ny, width, height)
					&& board[ny * width + nx])
					count++;
			}
			dx++;
		}
		dy++;
	}
	return (count);
}

static void	step(char *board, int width, int height)
{
	char	*next;
	int		x;
	int		y;
	int		neighbors;
	int		i;

	next = calloc(width * height, sizeof(char));
	if (!next)
		return ;

	y = 0;
	while (y < height)
	{
		x = 0;
		while (x < width)
		{
			neighbors = count_neighbors(board, x, y, width, height);

			if (board[y * width + x])
			{
				if (neighbors == 2 || neighbors == 3)
					next[y * width + x] = 1;
			}
			else if (neighbors == 3)
				next[y * width + x] = 1;

			x++;
		}
		y++;
	}

	i = 0;
	while (i < width * height)
	{
		board[i] = next[i];
		i++;
	}
	free(next);
}

static void	draw_board(char *board, int width, int height)
{
	int	x;
	int	y;

	y = 0;
	while (y < height)
	{
		x = 0;
		while (x < width)
		{
			if (board[y * width + x])
				putchar('0');
			else
				putchar(' ');
			x++;
		}
		putchar('\n');
		y++;
	}
}

static void	read_commands(char *board, int width, int height)
{
	char	c;
	int		x;
	int		y;
	int		drawing;

	x = 0;
	y = 0;
	drawing = 0;

	while (read(0, &c, 1) > 0)
	{
		if (c == 'x')
		{
			drawing = !drawing;
			if (drawing)
				board[y * width + x] = 1;
		}
		else if (c == 'w' && y > 0)
			y--;
		else if (c == 's' && y < height - 1)
			y++;
		else if (c == 'a' && x > 0)
			x--;
		else if (c == 'd' && x < width - 1)
			x++;

		/*
		 * Draw after processing the command.
		 * Movement commands draw if the pen is down.
		 */
		if (drawing && c != 'x')
			board[y * width + x] = 1;
	}
}

int	main(int argc, char **argv)
{
	int		width;
	int		height;
	int		iterations;
	int		i;
	char	*board;

	if (argc != 4)
		return (1);

	width = atoi(argv[1]);
	height = atoi(argv[2]);
	iterations = atoi(argv[3]);

	if (width <= 0 || height <= 0 || iterations < 0)
		return (1);

	board = calloc(width * height, sizeof(char));
	if (!board)
		return (1);

	read_commands(board, width, height);

	i = 0;
	while (i < iterations)
	{
		step(board, width, height);
		i++;
	}

	draw_board(board, width, height);
	free(board);
	return (0);
}
