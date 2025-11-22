#!/usr/bin/env python3
"""
可视化评估结果：FID、Label Score、Entropy在不同标签中心的变化
用于分析ID区域和OOD区域的性能差异
"""

import numpy as np
import matplotlib.pyplot as plt
import argparse
import os
from pathlib import Path

def load_eval_data(npz_path):
    """加载评估数据"""
    data = np.load(npz_path)
    print(f"\n{'='*80}")
    print(f"加载文件: {npz_path}")
    print(f"{'='*80}")
    print("\n文件包含的键:")
    for key in data.keys():
        print(f"  - {key}: shape={data[key].shape}, dtype={data[key].dtype}")
    
    # 提取数据（注意：npz文件中的键名是复数形式）
    centers = data.get('centers', None)
    fid = data.get('fids', None)  # 注意：键名是 'fids' 不是 'fid'
    ls = data.get('labelscores', None)  # 注意：键名是 'labelscores' 不是 'ls'
    entropy = data.get('entropies', None)  # 注意：键名是 'entropies' 不是 'entropy'
    nrealimgs = data.get('nrealimgs', None)  # 每个中心的真实图像数量（可选）
    
    if centers is None:
        # 如果没有centers，尝试从其他键推断
        if fid is not None:
            centers = np.arange(len(fid))
        elif ls is not None:
            centers = np.arange(len(ls))
        else:
            raise ValueError("无法确定centers，请检查npz文件结构")
    
    return {
        'centers': centers,
        'fid': fid,
        'ls': ls,
        'entropy': entropy
    }

def visualize_single_experiment(data, output_path, id_min=0, id_max=45, ood_min=45, ood_max=90, 
                                experiment_name="Experiment"):
    """可视化单个实验的结果"""
    centers = data['centers']
    fid = data['fid']
    ls = data['ls']
    entropy = data['entropy']
    
    # 创建图形
    fig, axes = plt.subplots(3, 1, figsize=(12, 10))
    fig.suptitle(f'{experiment_name} - ID vs OOD Performance', fontsize=16, fontweight='bold')
    
    # 确定ID和OOD区域
    id_mask = (centers >= id_min) & (centers <= id_max)
    ood_mask = (centers >= ood_min) & (centers <= ood_max)
    
    # 1. FID (越低越好)
    ax1 = axes[0]
    if fid is not None:
        ax1.plot(centers[id_mask], fid[id_mask], 'o-', color='blue', label=f'ID Region [{id_min}, {id_max}]', linewidth=0.1, markersize=4)
        ax1.plot(centers[ood_mask], fid[ood_mask], 's-', color='red', label=f'OOD Region [{ood_min}, {ood_max}]', linewidth=0.1, markersize=4)
        ax1.axvline(x=id_max, color='gray', linestyle='--', linewidth=0.1, alpha=0.7, label='ID/OOD Boundary')
        ax1.set_ylabel('FID', fontsize=12, fontweight='bold')
        ax1.set_title('FID (Fréchet Inception Distance) - Lower is Better', fontsize=13)
        ax1.grid(True, alpha=0.3)
        ax1.legend(loc='best', fontsize=10)
        
        # 计算平均FID
        if np.any(id_mask):
            avg_fid_id = np.mean(fid[id_mask])
            ax1.axhline(y=avg_fid_id, color='blue', linestyle=':', alpha=0.5, linewidth=0.1)
            ax1.text(0.02, 0.95, f'Avg FID (ID): {avg_fid_id:.4f}', transform=ax1.transAxes, 
                    fontsize=10, verticalalignment='top', bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.5))
        if np.any(ood_mask):
            avg_fid_ood = np.mean(fid[ood_mask])
            ax1.axhline(y=avg_fid_ood, color='red', linestyle=':', alpha=0.5, linewidth=0.1)
            ax1.text(0.02, 0.85, f'Avg FID (OOD): {avg_fid_ood:.4f}', transform=ax1.transAxes, 
                    fontsize=10, verticalalignment='top', bbox=dict(boxstyle='round', facecolor='lightcoral', alpha=0.5))
    
    # 2. Label Score (越高越好)
    ax2 = axes[1]
    if ls is not None:
        ax2.plot(centers[id_mask], ls[id_mask], 'o-', color='blue', label=f'ID Region [{id_min}, {id_max}]', linewidth=2, markersize=4)
        ax2.plot(centers[ood_mask], ls[ood_mask], 's-', color='red', label=f'OOD Region [{ood_min}, {ood_max}]', linewidth=2, markersize=4)
        ax2.axvline(x=id_max, color='gray', linestyle='--', linewidth=1.5, alpha=0.7, label='ID/OOD Boundary')
        ax2.set_ylabel('Label Score', fontsize=12, fontweight='bold')
        ax2.set_title('Label Score (Age Prediction Accuracy) - Higher is Better', fontsize=13)
        ax2.grid(True, alpha=0.3)
        ax2.legend(loc='best', fontsize=10)
        
        # 计算平均LS
        if np.any(id_mask):
            avg_ls_id = np.mean(ls[id_mask])
            ax2.axhline(y=avg_ls_id, color='blue', linestyle=':', alpha=0.5, linewidth=1)
            ax2.text(0.02, 0.95, f'Avg LS (ID): {avg_ls_id:.4f}', transform=ax2.transAxes, 
                    fontsize=10, verticalalignment='top', bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.5))
        if np.any(ood_mask):
            avg_ls_ood = np.mean(ls[ood_mask])
            ax2.axhline(y=avg_ls_ood, color='red', linestyle=':', alpha=0.5, linewidth=1)
            ax2.text(0.02, 0.85, f'Avg LS (OOD): {avg_ls_ood:.4f}', transform=ax2.transAxes, 
                    fontsize=10, verticalalignment='top', bbox=dict(boxstyle='round', facecolor='lightcoral', alpha=0.5))
    
    # 3. Entropy (多样性指标，适中最好)
    ax3 = axes[2]
    if entropy is not None:
        ax3.plot(centers[id_mask], entropy[id_mask], 'o-', color='blue', label=f'ID Region [{id_min}, {id_max}]', linewidth=2, markersize=4)
        ax3.plot(centers[ood_mask], entropy[ood_mask], 's-', color='red', label=f'OOD Region [{ood_min}, {ood_max}]', linewidth=2, markersize=4)
        ax3.axvline(x=id_max, color='gray', linestyle='--', linewidth=1.5, alpha=0.7, label='ID/OOD Boundary')
        ax3.set_xlabel('Label (Rotation Angle in Degrees)', fontsize=12, fontweight='bold')
        ax3.set_ylabel('Entropy', fontsize=12, fontweight='bold')
        ax3.set_title('Entropy (Diversity) - Moderate is Best', fontsize=13)
        ax3.grid(True, alpha=0.3)
        ax3.legend(loc='best', fontsize=10)
        
        # 计算平均Entropy
        if np.any(id_mask):
            avg_entropy_id = np.mean(entropy[id_mask])
            ax3.axhline(y=avg_entropy_id, color='blue', linestyle=':', alpha=0.5, linewidth=1)
            ax3.text(0.02, 0.95, f'Avg Entropy (ID): {avg_entropy_id:.4f}', transform=ax3.transAxes, 
                    fontsize=10, verticalalignment='top', bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.5))
        if np.any(ood_mask):
            avg_entropy_ood = np.mean(entropy[ood_mask])
            ax3.axhline(y=avg_entropy_ood, color='red', linestyle=':', alpha=0.5, linewidth=1)
            ax3.text(0.02, 0.85, f'Avg Entropy (OOD): {avg_entropy_ood:.4f}', transform=ax3.transAxes, 
                    fontsize=10, verticalalignment='top', bbox=dict(boxstyle='round', facecolor='lightcoral', alpha=0.5))
    
    plt.tight_layout()
    
    # 保存图片
    if output_path:
        plt.savefig(output_path, dpi=300, bbox_inches='tight')
        print(f"\n✅ 可视化结果已保存到: {output_path}")
    else:
        plt.show()
    
    return fig

def visualize_comparison(experiment_paths, output_path, id_min=0, id_max=45, ood_min=45, ood_max=90):
    """对比多个实验的结果"""
    experiments_data = []
    experiment_names = []
    
    for exp_path in experiment_paths:
        exp_path_obj = Path(exp_path)
        # 从路径提取实验名称：eval_xxx的父目录名就是实验名称
        # 例如：/path/to/output/RC-49_64/simple_mix_baseline/eval_2025-11-21_15-45-42
        # parent 是 simple_mix_baseline
        exp_name = exp_path_obj.parent.name  # 从路径提取实验名称
        npz_file = exp_path_obj / 'fid_ls_entropy_over_centers.npz'
        
        if not npz_file.exists():
            print(f"⚠️  警告: 找不到文件 {npz_file}")
            continue
        
        # 静默加载数据（不打印详细信息）
        data_dict = np.load(str(npz_file))
        # 注意：npz文件中的键名是复数形式
        centers = data_dict.get('centers', None)
        fid = data_dict.get('fids', None)  # 键名是 'fids' 不是 'fid'
        ls = data_dict.get('labelscores', None)  # 键名是 'labelscores' 不是 'ls'
        entropy = data_dict.get('entropies', None)  # 键名是 'entropies' 不是 'entropy'
        nrealimgs = data_dict.get('nrealimgs', None)  # 每个中心的真实图像数量（可选）
        
        # 检查数据是否有效
        if fid is None and ls is None and entropy is None:
            print(f"⚠️  警告: {exp_name} 的数据文件为空（没有找到fids/labelscores/entropies）")
            continue
        
        if centers is None:
            if fid is not None:
                centers = np.arange(len(fid))
            elif ls is not None:
                centers = np.arange(len(ls))
            elif entropy is not None:
                centers = np.arange(len(entropy))
            else:
                print(f"⚠️  警告: {exp_name} 无法确定centers")
                continue
        
        # 检查数据长度是否匹配
        data_lengths = {}
        if fid is not None:
            data_lengths['fids'] = len(fid)
        if ls is not None:
            data_lengths['labelscores'] = len(ls)
        if entropy is not None:
            data_lengths['entropies'] = len(entropy)
        
        if len(set(data_lengths.values())) > 1:
            print(f"⚠️  警告: {exp_name} 的数据长度不一致: {data_lengths}")
        
        if len(centers) != data_lengths.get('fids', data_lengths.get('labelscores', data_lengths.get('entropies', len(centers)))):
            print(f"⚠️  警告: {exp_name} centers长度({len(centers)})与数据长度不匹配")
        
        data = {
            'centers': centers,
            'fid': fid,
            'ls': ls,
            'entropy': entropy,
            'nrealimgs': nrealimgs
        }
        
        experiments_data.append(data)
        experiment_names.append(exp_name)
        
        # 显示加载的数据信息
        info_parts = []
        if fid is not None:
            info_parts.append(f"FID({len(fid)})")
        if ls is not None:
            info_parts.append(f"LS({len(ls)})")
        if entropy is not None:
            info_parts.append(f"Entropy({len(entropy)})")
        print(f"✅ 加载: {exp_name} - {', '.join(info_parts)}, Centers({len(centers)})")
    
    if len(experiments_data) == 0:
        print("❌ 错误: 没有找到有效的评估数据！")
        return
    
    # 创建对比图（增大图形尺寸以减少拥挤感）
    fig, axes = plt.subplots(3, 1, figsize=(16, 12))
    fig.suptitle('Comparison: ID vs OOD Performance Across Experiments', fontsize=16, fontweight='bold')
    
    # 使用更好的颜色方案和线条样式
    # 为不同实验定义不同的样式组合
    line_styles = ['-', '--', '-.', ':', '-']  # 实线、虚线、点划线、点线、实线
    markers = ['o', 's', '^', 'v', 'D']  # 圆形、方形、上三角、下三角、菱形
    # 使用更易区分的颜色（使用tab10调色板，但调整顺序）
    base_colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22', '#17becf']
    colors = [base_colors[i % len(base_colors)] for i in range(len(experiments_data))]
    
    for idx, (data, name) in enumerate(zip(experiments_data, experiment_names)):
        centers = data['centers']
        fid = data['fid']
        ls = data['ls']
        entropy = data['entropy']
        
        # 计算标记间距：数据点太多时，每隔N个点标记一次
        # RC-49数据集通常有899个点，每隔20-30个点标记一次比较合适，减少拥挤感
        if len(centers) > 500:
            markevery = max(1, len(centers) // 25)  # 大约25个标记点
        elif len(centers) > 200:
            markevery = max(1, len(centers) // 20)  # 大约20个标记点
        elif len(centers) > 100:
            markevery = max(1, len(centers) // 15)  # 大约15个标记点
        else:
            markevery = max(1, len(centers) // 10)  # 至少10个标记点
        
        linestyle = line_styles[idx % len(line_styles)]
        marker = markers[idx % len(markers)]
        color = colors[idx]
        
        # 为baseline_id_only使用更粗的线条和更明显的样式以突出显示
        if 'baseline_id_only' in name.lower():
            linewidth = 2.5  # 更粗的线条
            marker_size = 6  # 更大的标记
            alpha = 1.0
            linestyle = '-'  # 强制使用实线
            marker = 'o'  # 强制使用圆形标记
            color = '#d62728'  # 红色突出显示
        elif 'oracle' in name.lower():
            linewidth = 2.0  # oracle也稍微粗一点
            marker_size = 4
            alpha = 0.95
        else:
            linewidth = 1.0  # 其他线条更细
            marker_size = 2.5  # 更小的标记
            alpha = 0.8  # 稍微透明一点
        
        # FID
        if fid is not None:
            axes[0].plot(centers, fid, marker=marker, linestyle=linestyle, color=color, 
                        label=name, linewidth=linewidth, markersize=marker_size, 
                        alpha=alpha, markevery=markevery)
        
        # Label Score
        if ls is not None:
            axes[1].plot(centers, ls, marker=marker, linestyle=linestyle, color=color, 
                        label=name, linewidth=linewidth, markersize=marker_size, 
                        alpha=alpha, markevery=markevery)
        
        # Entropy
        if entropy is not None:
            axes[2].plot(centers, entropy, marker=marker, linestyle=linestyle, color=color, 
                        label=name, linewidth=linewidth, markersize=marker_size, 
                        alpha=alpha, markevery=markevery)
    
    # 添加ID/OOD边界线（只在一个轴上添加标签，避免重复）
    for idx, ax in enumerate(axes):
        if idx == 0:
            ax.axvline(x=id_max, color='gray', linestyle='--', linewidth=1.5, alpha=0.6, label='ID/OOD Boundary', zorder=0)
        else:
            ax.axvline(x=id_max, color='gray', linestyle='--', linewidth=1.5, alpha=0.6, zorder=0)
        ax.grid(True, alpha=0.2, linestyle=':', linewidth=0.5, zorder=0)  # 更淡的网格线
        
        # 优化图例：放在图外右侧，使用两列布局以节省空间
        n_legend_items = len(experiments_data) + 1  # +1 for boundary line
        if n_legend_items > 6:
            ncol = 2  # 如果图例项太多，使用两列
        else:
            ncol = 1
        ax.legend(loc='upper left', fontsize=8.5, framealpha=0.95, 
                 edgecolor='gray', fancybox=True, shadow=True,
                 ncol=ncol, columnspacing=0.8, handlelength=2.5)
    
    # 调整子图间距，让图例有足够空间
    plt.subplots_adjust(hspace=0.4, right=0.75)  # 增加子图间距，右侧留出图例空间
    
    axes[0].set_ylabel('FID', fontsize=12, fontweight='bold')
    axes[0].set_title('FID Comparison - Lower is Better', fontsize=13)
    
    axes[1].set_ylabel('Label Score', fontsize=12, fontweight='bold')
    axes[1].set_title('Label Score Comparison - Higher is Better', fontsize=13)
    
    axes[2].set_xlabel('Label (Rotation Angle in Degrees)', fontsize=12, fontweight='bold')
    axes[2].set_ylabel('Entropy', fontsize=12, fontweight='bold')
    axes[2].set_title('Entropy Comparison - Moderate is Best', fontsize=13)
    
    plt.tight_layout()
    
    if output_path:
        plt.savefig(output_path, dpi=300, bbox_inches='tight')
        print(f"\n✅ 对比图已保存到: {output_path}")
    else:
        plt.show()
    
    return fig

def main():
    parser = argparse.ArgumentParser(description='可视化评估结果：FID、Label Score、Entropy在不同标签中心的变化')
    parser.add_argument('--npz_path', type=str, default=None,
                       help='fid_ls_entropy_over_centers.npz文件的路径（单实验模式必需，对比模式不需要）')
    parser.add_argument('--output_path', type=str, default=None,
                       help='输出图片路径（默认：与npz文件同目录，文件名加_visualization.png）')
    parser.add_argument('--id_min', type=float, default=0.0,
                       help='ID区域最小标签（默认：0.0）')
    parser.add_argument('--id_max', type=float, default=45.0,
                       help='ID区域最大标签（默认：45.0）')
    parser.add_argument('--ood_min', type=float, default=45.0,
                       help='OOD区域最小标签（默认：45.0）')
    parser.add_argument('--ood_max', type=float, default=90.0,
                       help='OOD区域最大标签（默认：90.0）')
    parser.add_argument('--experiment_name', type=str, default=None,
                       help='实验名称（用于图表标题）')
    parser.add_argument('--compare', type=str, nargs='+', default=None,
                       help='对比模式：提供多个eval目录路径，生成对比图')
    
    args = parser.parse_args()
    
    # 对比模式
    if args.compare:
        output_path = args.output_path or 'experiments/RC64/eval_comparison.png'
        visualize_comparison(args.compare, output_path, args.id_min, args.id_max, args.ood_min, args.ood_max)
        return
    
    # 单实验模式：需要npz_path
    if args.npz_path is None:
        print("❌ 错误: 单实验模式需要提供 --npz_path 参数")
        print("   用法: python visualize_eval_results.py --npz_path <npz文件路径>")
        print("   或使用对比模式: python visualize_eval_results.py --compare <目录1> <目录2> ...")
        return
    
    npz_path = Path(args.npz_path)
    if not npz_path.exists():
        print(f"❌ 错误: 文件不存在: {npz_path}")
        return
    
    # 加载数据
    data = load_eval_data(str(npz_path))
    
    # 确定输出路径
    if args.output_path:
        output_path = args.output_path
    else:
        output_path = npz_path.parent / f"{npz_path.stem}_visualization.png"
    
    # 确定实验名称
    if args.experiment_name:
        exp_name = args.experiment_name
    else:
        exp_name = npz_path.parent.parent.name  # 从路径推断
    
    # 可视化
    visualize_single_experiment(data, str(output_path), args.id_min, args.id_max, 
                               args.ood_min, args.ood_max, exp_name)
    
    # 打印统计信息
    print(f"\n{'='*80}")
    print("统计摘要:")
    print(f"{'='*80}")
    centers = data['centers']
    id_mask = (centers >= args.id_min) & (centers <= args.id_max)
    ood_mask = (centers >= args.ood_min) & (centers <= args.ood_max)
    
    if data['fid'] is not None:
        print(f"\nFID:")
        if np.any(id_mask):
            print(f"  ID区域 [{args.id_min}, {args.id_max}]: 平均={np.mean(data['fid'][id_mask]):.4f}, 最小={np.min(data['fid'][id_mask]):.4f}, 最大={np.max(data['fid'][id_mask]):.4f}")
        if np.any(ood_mask):
            print(f"  OOD区域 [{args.ood_min}, {args.ood_max}]: 平均={np.mean(data['fid'][ood_mask]):.4f}, 最小={np.min(data['fid'][ood_mask]):.4f}, 最大={np.max(data['fid'][ood_mask]):.4f}")
    
    if data['ls'] is not None:
        print(f"\nLabel Score:")
        if np.any(id_mask):
            print(f"  ID区域 [{args.id_min}, {args.id_max}]: 平均={np.mean(data['ls'][id_mask]):.4f}, 最小={np.min(data['ls'][id_mask]):.4f}, 最大={np.max(data['ls'][id_mask]):.4f}")
        if np.any(ood_mask):
            print(f"  OOD区域 [{args.ood_min}, {args.ood_max}]: 平均={np.mean(data['ls'][ood_mask]):.4f}, 最小={np.min(data['ls'][ood_mask]):.4f}, 最大={np.max(data['ls'][ood_mask]):.4f}")
    
    if data['entropy'] is not None:
        print(f"\nEntropy:")
        if np.any(id_mask):
            print(f"  ID区域 [{args.id_min}, {args.id_max}]: 平均={np.mean(data['entropy'][id_mask]):.4f}, 最小={np.min(data['entropy'][id_mask]):.4f}, 最大={np.max(data['entropy'][id_mask]):.4f}")
        if np.any(ood_mask):
            print(f"  OOD区域 [{args.ood_min}, {args.ood_max}]: 平均={np.mean(data['entropy'][ood_mask]):.4f}, 最小={np.min(data['entropy'][ood_mask]):.4f}, 最大={np.max(data['entropy'][ood_mask]):.4f}")
    
    print(f"\n{'='*80}\n")

if __name__ == "__main__":
    main()



