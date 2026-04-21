import 'package:flutter/material.dart';

// [GAP] Vertical/Height
const SIZED_BOX_H2 = SizedBox(height: 2);
const SIZED_BOX_H4 = SizedBox(height: 4);
const SIZED_BOX_H6 = SizedBox(height: 6);
const SIZED_BOX_H8 = SizedBox(height: 8);
const SIZED_BOX_H10 = SizedBox(height: 10);
const SIZED_BOX_H12 = SizedBox(height: 12);
const SIZED_BOX_H16 = SizedBox(height: 16);
const SIZED_BOX_H20 = SizedBox(height: 20);
const SIZED_BOX_H24 = SizedBox(height: 24);
const SIZED_BOX_H32 = SizedBox(height: 32);
const SIZED_BOX_H40 = SizedBox(height: 40);
const SIZED_BOX_H48 = SizedBox(height: 48);
const SIZED_BOX_H56 = SizedBox(height: 56);
const SIZED_BOX_H64 = SizedBox(height: 64);

// [GAP] Horizontal/Width
const SIZED_BOX_W2 = SizedBox(width: 2);
const SIZED_BOX_W4 = SizedBox(width: 4);
const SIZED_BOX_W6 = SizedBox(width: 6);
const SIZED_BOX_W8 = SizedBox(width: 8);
const SIZED_BOX_W10 = SizedBox(width: 10);
const SIZED_BOX_W12 = SizedBox(width: 12);
const SIZED_BOX_W16 = SizedBox(width: 16);
const SIZED_BOX_W20 = SizedBox(width: 20);
const SIZED_BOX_W24 = SizedBox(width: 24);
const SIZED_BOX_W32 = SizedBox(width: 32);

// [SPACER]
const SPACER = Spacer();

// [PADDING]
abstract final class AppPadding {
  static const double XS = 4;
  static const double SM = 8;
  static const double MD = 12;
  static const double BASE = 16;
  static const double LG = 20;
  static const double XL = 24;
  static const double XXL = 32;
  static const double XXXL = 40;
}

// [BORDER RADIUS]
abstract final class AppRadius {
  static const double XS = 4;
  static const double SM = 8;
  static const double MD = 12;
  static const double BASE = 16;
  static const double LG = 20;
  static const double XL = 24;
  static const double FULL = 999;
}
