#!/usr/bin/env python3
"""
检查 npz 文件内容的工具脚本
用于查看 fid_ls_entropy_over_centers.npz 文件中包含的所有数据
"""

import numpy as np
import argparse
from pathlib import Path

def inspect_npz(npz_path):
    """检查npz文件的内容"""
    npz_path = Path(npz_path)
    
    if not npz_path.exists():
        print(f"❌ 错误: 文件不存在: {npz_path}")
        return
    
    print(f"\n{'='*80}")
    print(f"检查文件: {npz_path}")
    print(f"{'='*80}\n")
    
    data = np.load(str(npz_path))
    
    print("文件包含的键:")
    print("-" * 80)
    for key in sorted(data.keys()):
        value = data[key]
        print(f"  {key:20s}: shape={value.shape:20s} dtype={value.dtype}")
        if value.size <= 10:
            print(f"                     值={value}")
        elif value.size <= 50:
            print(f"                     前5个值={value[:5]}")
        else:
            print(f"                     前5个值={value[:5]}")
            print(f"                     最后5个值={value[-5:]}")
            print(f"                     最小值={np.min(value):.6f}, 最大值={np.max(value):.6f}, 平均值={np.mean(value):.6f}")
    
    print("\n" + "="*80)
    print("数据摘要:")
    print("="*80)
    
    # 检查主要数据
    if 'centers' in data:
        centers = data['centers']
        print(f"\nCenters (标签中心):")
        print(f"  数量: {len(centers)}")
        print(f"  范围: [{np.min(centers):.6f}, {np.max(centers):.6f}]")
        print(f"  前5个: {centers[:5]}")
        if len(centers) > 5:
            print(f"  最后5个: {centers[-5:]}")
    
    if 'fids' in data:
        fids = data['fids']
        print(f"\nFIDs (Fréchet Inception Distance):")
        print(f"  数量: {len(fids)}")
        print(f"  平均值(SFID): {np.mean(fids):.6f}")
        print(f"  标准差: {np.std(fids):.6f}")
        print(f"  最小值: {np.min(fids):.6f}")
        print(f"  最大值: {np.max(fids):.6f}")
    
    if 'labelscores' in data:
        labelscores = data['labelscores']
        print(f"\nLabel Scores (标签预测准确度):")
        print(f"  数量: {len(labelscores)}")
        print(f"  平均值: {np.mean(labelscores):.6f}")
        print(f"  标准差: {np.std(labelscores):.6f}")
        print(f"  最小值: {np.min(labelscores):.6f}")
        print(f"  最大值: {np.max(labelscores):.6f}")
    
    if 'entropies' in data:
        entropies = data['entropies']
        print(f"\nEntropies (生成多样性):")
        print(f"  数量: {len(entropies)}")
        print(f"  平均值: {np.mean(entropies):.6f}")
        print(f"  标准差: {np.std(entropies):.6f}")
        print(f"  最小值: {np.min(entropies):.6f}")
        print(f"  最大值: {np.max(entropies):.6f}")
    
    if 'nrealimgs' in data:
        nrealimgs = data['nrealimgs']
        print(f"\nNRealImgs (每个中心的真实图像数量):")
        print(f"  数量: {len(nrealimgs)}")
        print(f"  总真实图像数: {int(np.sum(nrealimgs))}")
        print(f"  平均每个中心: {np.mean(nrealimgs):.2f}")
        print(f"  最小值: {int(np.min(nrealimgs))}")
        print(f"  最大值: {int(np.max(nrealimgs))}")
    
    # 检查数据一致性
    print(f"\n{'='*80}")
    print("数据一致性检查:")
    print("="*80)
    
    lengths = {}
    for key in ['centers', 'fids', 'labelscores', 'entropies', 'nrealimgs']:
        if key in data:
            lengths[key] = len(data[key])
    
    if len(set(lengths.values())) > 1:
        print("⚠️  警告: 数据长度不一致！")
        for key, length in lengths.items():
            print(f"  {key}: {length}")
    else:
        print("✅ 所有数据的长度一致")
        if lengths:
            print(f"  统一长度: {list(lengths.values())[0]}")
    
    print(f"\n{'='*80}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='检查 npz 文件的内容')
    parser.add_argument('npz_path', type=str, help='npz文件路径')
    args = parser.parse_args()
    
    inspect_npz(args.npz_path)

