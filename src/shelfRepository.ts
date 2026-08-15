import { normalizePath, Notice, Plugin } from 'obsidian';
import ApiRouter from './api-router';
import type { ShelfBookItem, ShelfCachePayload } from './models';

const CACHE_FILE_NAME = 'bookshelf-cache.json';
const CACHE_VERSION = 1 as const;

export default class ShelfRepository {
	private cacheNoticeShown = false;

	constructor(private plugin: Plugin, private apiManager: ApiRouter) {}

	async getShelfBooks(): Promise<ShelfBookItem[]> {
		const remoteShelf = await this.apiManager.getShelf();
		if (remoteShelf && Array.isArray(remoteShelf.books)) {
			await this.saveCache(remoteShelf.books);
			this.cacheNoticeShown = false;
			return remoteShelf.books;
		}

		const cachedShelf = await this.loadCache();
		if (cachedShelf) {
			if (!this.cacheNoticeShown) {
				new Notice('真实书架接口暂时不可用，已显示上次成功缓存的书架');
				this.cacheNoticeShown = true;
			}
			return cachedShelf.books;
		}

		throw new Error('无法获取微信读书真实书架，且本地没有可用缓存');
	}

	private get cachePath(): string {
		const pluginDir = this.plugin.manifest.dir;
		if (!pluginDir) {
			throw new Error('无法确定插件目录，不能读写书架缓存');
		}
		return normalizePath(`${pluginDir}/${CACHE_FILE_NAME}`);
	}

	private async saveCache(books: ShelfBookItem[]): Promise<void> {
		const payload: ShelfCachePayload = {
			version: CACHE_VERSION,
			cachedAt: Date.now(),
			books
		};
		try {
			await this.plugin.app.vault.adapter.write(
				this.cachePath,
				JSON.stringify(payload, null, 2)
			);
		} catch (error) {
			console.warn('[weread shelf persistent] 保存书架缓存失败', error);
		}
	}

	private async loadCache(): Promise<ShelfCachePayload | undefined> {
		try {
			if (!(await this.plugin.app.vault.adapter.exists(this.cachePath))) {
				return undefined;
			}
			const content = await this.plugin.app.vault.adapter.read(this.cachePath);
			const payload = JSON.parse(content) as ShelfCachePayload;
			if (payload.version !== CACHE_VERSION || !Array.isArray(payload.books)) {
				return undefined;
			}
			return payload;
		} catch (error) {
			console.warn('[weread shelf persistent] 读取书架缓存失败', error);
			return undefined;
		}
	}
}
