using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

public partial class PaintUtilsCS : Node
{
	public void UpdatePaint(Rect2 update_rect, Godot.Collections.Array<Godot.Collections.Array<int>> paint, Godot.Collections.Array<Godot.Collections.Array<bool>> updated, TileMap map, Color[] palette)
	{
		for (int x = (int)update_rect.Position.X; x < (int)update_rect.End.X; x++)
		{
			for (int y = (int)update_rect.Position.Y; y < (int)update_rect.End.Y; y++)
			{
				if (!(!updated[y][x] || !updated[y][x + 1] || !updated[y + 1][x] || !updated[y + 1][x + 1])) { continue; }

				for (int i = 0; i < palette.Length; i++) { map.SetCell(i, new Vector2I(x, y)); }

				int spot = paint[y][x];
				List<int> donecol = new List<int> { };
				int[] cols = { paint[y][x], paint[y][x + 1], paint[y + 1][x], paint[y + 1][x + 1] };
				for (int i = 0; i < cols.Length; i++)
				{
					int col = cols[i];
					if (donecol.Contains(col) || col == 0) { continue; }
					donecol.Add(col);
					int val = (spot == col ? 1 : 0) + ((paint[y][x + 1] == col ? 1 : 0) << 1) + ((paint[y + 1][x + 1] == col ? 1 : 0) << 2) + ((paint[y + 1][x] == col ? 1 : 0) << 3);
					if (val > 0)
					{
						map.SetCell(col - 1, new Vector2I(x, y), 0, new Vector2I(val % 4, val / 4));
					}
				}
				updated[y][x] = true;
			}
		}
	}
}
